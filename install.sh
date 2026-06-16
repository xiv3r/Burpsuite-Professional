#!/bin/bash
set -euo pipefail

# Installing Dependencies
echo "Installing Dependencies..."
sudo apt update
sudo apt install git wget openjdk-21-jre -y

# Cloning
INSTALL_DIR="$HOME/Burpsuite-Professional"
if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" pull --ff-only
else
    if [[ -e "$INSTALL_DIR" ]]; then
        mv "$INSTALL_DIR" "$INSTALL_DIR.bak.$(date +%s)"
    fi
    git clone --depth 1 "https://github.com/xiv3r/Burpsuite-Professional.git" "$INSTALL_DIR"
fi
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
EXPECTED_SHA256=$(printf '%s' "$EXPECTED_SHA256" | tr -d '[:space:]')
EXPECTED_SHA256=$(printf '%s' "$EXPECTED_SHA256" | tr '[:upper:]' '[:lower:]')
if [[ -z "$EXPECTED_SHA256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi

# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
wget -O "burpsuite_pro_v${version}.jar" "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${version}.jar"

actual_sha256=$(sha256sum "burpsuite_pro_v${version}.jar" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for burpsuite_pro_v${version}.jar: expected ${EXPECTED_SHA256}, got ${actual_sha256}." >&2
    exit 1
fi
echo "SHA-256 verified for burpsuite_pro_v${version}.jar"

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
actual_loader_sha256=$(sha256sum loader.jar | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
if [[ "$actual_loader_sha256" != "$EXPECTED_LOADER_SHA256" ]]; then
    echo "Error: SHA-256 mismatch for loader.jar: expected ${EXPECTED_LOADER_SHA256}, got ${actual_loader_sha256}." >&2
    exit 1
fi
echo "SHA-256 verified for loader.jar"
# Execute Key Generator
echo "Starting Key loader.jar..."
(java -jar loader.jar) &

# Execute Burpsuite Professional
echo "Executing Burpsuite Professional..."
cat > burpsuitepro <<EOF
#!/bin/bash
set -euo pipefail
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"${INSTALL_DIR}/loader.jar" -noverify -jar "${INSTALL_DIR}/burpsuite_pro_v${version}.jar" &
EOF

chmod +x burpsuitepro

if [[ "$EUID" -eq 0 ]]; then
    cp burpsuitepro /bin/burpsuitepro
else
    sudo cp burpsuitepro /bin/burpsuitepro
fi

./burpsuitepro
