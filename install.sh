#!/bin/bash
set -euo pipefail

# Resolve the directory where this script lives so that lib.sh can be sourced
# both from a git checkout and from a bootstrap temp dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

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

read_version
expected_sha256=$(read_value "BURP_SHA256")
if [[ -z "$expected_sha256" ]]; then
    echo "Error: BURP_SHA256 is empty." >&2
    exit 1
fi

# Download Burpsuite Professional
download_with_hash \
    "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${bp_version}.jar" \
    "burpsuite_pro_v${bp_version}.jar" \
    "$expected_sha256"

verify_loader

# Execute Key Generator
echo "Starting Key loader.jar..."
(java -jar loader.jar) &

# Execute Burpsuite Professional
echo "Executing Burpsuite Professional..."
cat > burpsuitepro <<EOF
#!/bin/bash
set -euo pipefail
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"${INSTALL_DIR}/loader.jar" -noverify -jar "${INSTALL_DIR}/burpsuite_pro_v${bp_version}.jar" &
EOF

chmod +x burpsuitepro

if [[ "$EUID" -eq 0 ]]; then
    cp burpsuitepro /bin/burpsuitepro
else
    sudo cp burpsuitepro /bin/burpsuitepro
fi

./burpsuitepro
