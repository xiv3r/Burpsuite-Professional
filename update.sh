#!/bin/bash
set -euo pipefail

# Refreshes the Burp Suite Professional install in place:
#   1. git pull in the existing install dir (no fresh clone)
#   2. re-read VERSION/BURP_SHA256/LOADER_SHA256
#   3. download the new Burp JAR and verify its hash
#   4. verify the bundled loader.jar
#   5. atomically replace /bin/burpsuitepro
#
# Does NOT install OS packages, the loader, or launch Burp.
# Run from the install directory; safe to invoke repeatedly.

INSTALL_DIR="$HOME/Burpsuite-Professional"

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    echo "Error: $INSTALL_DIR is not a git checkout. Run install.sh first." >&2
    exit 1
fi

git -C "$INSTALL_DIR" pull --ff-only
cd "$INSTALL_DIR"

version=$(cat VERSION)
version=$(printf '%s' "$version" | tr -d '[:space:]')
if [[ -z "$version" ]]; then
    echo "Error: VERSION file is empty." >&2
    exit 1
fi

if [[ ! -f BURP_SHA256 ]]; then
    echo "Error: BURP_SHA256 file not found." >&2
    exit 1
fi
EXPECTED_SHA256=$(<BURP_SHA256)
EXPECTED_SHA256=$(printf '%s' "$EXPECTED_SHA256" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ -z "$EXPECTED_SHA256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi

if [[ ! -f LOADER_SHA256 ]]; then
    echo "Error: LOADER_SHA256 file not found." >&2
    exit 1
fi
EXPECTED_LOADER_SHA256=$(<LOADER_SHA256)
EXPECTED_LOADER_SHA256=$(printf '%s' "$EXPECTED_LOADER_SHA256" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ -z "$EXPECTED_LOADER_SHA256" ]]; then
    echo "Error: LOADER_SHA256 is empty." >&2
    exit 1
fi

echo "Downloading Burp Suite Professional ${version}..."
wget -O "burpsuite_pro_v${version}.jar" "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${version}.jar"

actual_sha256=$(sha256sum "burpsuite_pro_v${version}.jar" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for burpsuite_pro_v${version}.jar: expected ${EXPECTED_SHA256}, got ${actual_sha256}." >&2
    exit 1
fi
echo "SHA-256 verified for burpsuite_pro_v${version}.jar"

actual_loader_sha256=$(sha256sum loader.jar | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
if [[ "$actual_loader_sha256" != "$EXPECTED_LOADER_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for loader.jar: expected ${EXPECTED_LOADER_SHA256}, got ${actual_loader_sha256}." >&2
    exit 1
fi
echo "SHA-256 verified for loader.jar"

cat > burpsuitepro <<EOF
#!/bin/bash
set -euo pipefail
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"${INSTALL_DIR}/loader.jar" -noverify -jar "${INSTALL_DIR}/burpsuite_pro_v${version}.jar" &
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
