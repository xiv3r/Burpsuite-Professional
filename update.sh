#!/bin/bash
set -euo pipefail

# Refreshes the Burp Suite Professional install in place.
# Does NOT install OS packages, the loader, or launch Burp.
# Run from the install directory; safe to invoke repeatedly.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

INSTALL_DIR="$HOME/Burpsuite-Professional"

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    echo "Error: $INSTALL_DIR is not a git checkout. Run install.sh first." >&2
    exit 1
fi

git -C "$INSTALL_DIR" pull --ff-only
cd "$INSTALL_DIR"

read_version
expected_sha256=$(read_value "BURP_SHA256")
if [[ -z "$expected_sha256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi

# Download and verify the new Burp JAR
download_with_hash \
    "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${bp_version}.jar" \
    "burpsuite_pro_v${bp_version}.jar" \
    "$expected_sha256"

verify_loader

# Recreate the launcher with the current version
cat > burpsuitepro <<EOF
#!/bin/bash
set -euo pipefail
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"${INSTALL_DIR}/loader.jar" -noverify -jar "${INSTALL_DIR}/burpsuite_pro_v${bp_version}.jar" &
EOF
chmod +x burpsuitepro

TMP_LAUNCHER="/bin/burpsuitepro.new.$$"
if [[ "$EUID" -eq 0 ]]; then
    cp burpsuitepro "$TMP_LAUNCHER"
    mv -f "$TMP_LAUNCHER" /bin/burpsuitepro
else
    sudo cp burpsuitepro "$TMP_LAUNCHER"
    sudo mv -f "$TMP_LAUNCHER" /bin/burpsuitepro
fi

echo "Launcher updated at /bin/burpsuitepro"
