#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/Burpsuite-Professional"
# Verify git is available before cloning/updating
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git not found. Please install git (e.g., brew install git)." >&2
    exit 1
fi

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

if [[ ! -f VERSION ]]; then
    echo "Error: VERSION file not found in ${INSTALL_DIR}." >&2
    exit 1
fi
version=$(cat VERSION)
version=$(printf '%s' "$version" | tr -d '[:space:]')
if [[ -z "$version" ]]; then
    echo "Error: VERSION file is empty." >&2
    exit 1
fi

# Verify prerequisites
if ! command -v java >/dev/null 2>&1; then
    echo "Error: java not found. Please install a full JDK (e.g., brew install openjdk@17)." >&2
    exit 1
fi

if ! command -v jpackage >/dev/null 2>&1; then
    echo "Error: jpackage not found. The JDK is incomplete; install a full JDK that includes jpackage." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl not found. Please install curl." >&2
    exit 1
fi

# Download Burp Suite Professional
echo "Downloading Burp Suite Professional Latest..."
url="https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${version}.jar"
curl -fL "$url" -o "burpsuite_pro_v${version}.jar"

if [[ ! -f BURP_SHA256 ]]; then
    echo "Error: BURP_SHA256 file not found." >&2
    exit 1
fi
EXPECTED_SHA256=$(<BURP_SHA256)
EXPECTED_SHA256=$(printf '%s' "$EXPECTED_SHA256" | tr -d '[:space:]')
if [[ -z "$EXPECTED_SHA256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi
ACTUAL_SHA256=$(shasum -a 256 "burpsuite_pro_v${version}.jar" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for burpsuite_pro_v${version}.jar (expected ${EXPECTED_SHA256}, got ${ACTUAL_SHA256})" >&2
    exit 1
fi
echo "SHA-256 hash verified."

# Verify bundled loader.jar
if [[ ! -f LOADER_SHA256 ]]; then
    echo "Error: LOADER_SHA256 file not found." >&2
    exit 1
fi
EXPECTED_LOADER_SHA256=$(<LOADER_SHA256)
EXPECTED_LOADER_SHA256=$(printf '%s' "$EXPECTED_LOADER_SHA256" | tr -d '[:space:]')
EXPECTED_LOADER_SHA256=$(printf '%s' "$EXPECTED_LOADER_SHA256" | tr '[:upper:]' '[:lower:]')
if [[ -z "$EXPECTED_LOADER_SHA256" ]]; then
    echo "Error: LOADER_SHA256 is empty." >&2
    exit 1
fi
actual_loader_sha256=$(shasum -a 256 loader.jar | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
if [[ "$actual_loader_sha256" != "$EXPECTED_LOADER_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for loader.jar: expected ${EXPECTED_LOADER_SHA256}, got ${actual_loader_sha256}." >&2
    exit 1
fi
echo "SHA-256 verified for loader.jar"
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
     -jar "burpsuite_pro_v${version}.jar" &
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
awk -v dir="${INSTALL_DIR}" -v ver="${version}" '
    { gsub(/__INSTALL_DIR__/, dir); gsub(/__VERSION__/, ver); print }
' burp > burp.tmp
mv burp.tmp burp
rm -f burp.bak
chmod +x burp

# Create native app bundle
echo "Creating Burp Suite Professional app bundle..."
jpackage --name "Burp Suite Professional" \
  --input "${INSTALL_DIR}" \
  --main-jar "burpsuite_pro_v${version}.jar" \
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
