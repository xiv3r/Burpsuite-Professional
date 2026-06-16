#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

INSTALL_DIR="$HOME/Burpsuite-Professional"

# Verify git is available before cloning/updating
require_command git || { echo "Error: git not found. Please install git (e.g., brew install git)." >&2; exit 1; }

# Verify prerequisites
require_command java || { echo "Error: java not found. Please install a full JDK (e.g., brew install openjdk@17)." >&2; exit 1; }
require_command jpackage || { echo "Error: jpackage not found. The JDK is incomplete; install a full JDK that includes jpackage." >&2; exit 1; }
require_command curl || { echo "Error: curl not found. Please install curl." >&2; exit 1; }

# Clone or update the installer repository
if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" pull --ff-only
else
    if [[ -e "$INSTALL_DIR" ]]; then
        mv "$INSTALL_DIR" "$INSTALL_DIR.bak.$(date +%s)"
    fi
    git clone --depth 1 "https://github.com/xiv3r/Burpsuite-Professional.git" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

read_version
expected_sha256=$(read_value "BURP_SHA256")
if [[ -z "$expected_sha256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi

# Download and verify Burp Suite Professional
download_with_hash \
    "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${bp_version}.jar" \
    "burpsuite_pro_v${bp_version}.jar" \
    "$expected_sha256"

verify_loader

# Execute Key Generator and Burp Suite simultaneously
echo "Starting Key loader.jar and Burp Suite Professional..."
java -jar loader.jar &
LOADER_PID=$!
sleep 2
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:loader.jar \
     -noverify \
     -jar "burpsuite_pro_v${bp_version}.jar" &
BURP_PID=$!

# Surface startup failures without blocking until the user closes Burp
sleep 2
if ! kill -0 "$LOADER_PID" >/dev/null 2>&1; then
    echo "Error: loader.jar exited unexpectedly." >&2
    exit 1
fi
if ! kill -0 "$BURP_PID" >/dev/null 2>&1; then
    echo "Error: Burp Suite Professional exited unexpectedly." >&2
    exit 1
fi

# Create command-line launcher
echo "Creating burp launcher..."
cat > burp <<'LAUNCHEREOF'
#!/bin/bash
set -euo pipefail
cd "__INSTALL_DIR__"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:loader.jar -noverify -jar "burpsuite_pro_v__VERSION__.jar" &
LAUNCHEREOF
awk -v dir="${INSTALL_DIR}" -v ver="${bp_version}" '
    { gsub(/__INSTALL_DIR__/, dir); gsub(/__VERSION__/, ver); print }
' burp > burp.tmp
mv burp.tmp burp
rm -f burp.bak
chmod +x burp

# Create native app bundle
echo "Creating Burp Suite Professional app bundle..."
jpackage --name "Burp Suite Professional" \
  --input "${INSTALL_DIR}" \
  --main-jar "burpsuite_pro_v${bp_version}.jar" \
  --type app-image \
  --icon "${INSTALL_DIR}/burp_suite.icns" \
  --dest "${HOME}/Applications/" \
  --java-options "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/java.lang=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED" \
  --java-options "-javaagent:\"${INSTALL_DIR}/loader.jar\"" \
  --java-options "-noverify"
