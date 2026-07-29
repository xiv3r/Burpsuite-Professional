#!/bin/bash

detect_pkg_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    fi
}

# Detect package manager
PKG_MANAGER=$(detect_pkg_manager)

echo "Detected package manager: $PKG_MANAGER"

# Installing Dependencies
echo "Installing Dependencies..."

case $PKG_MANAGER in
    "apt")
        sudo apt update
        sudo apt install -y git wget openjdk-21-jre
        INSTALL_DIR="/bin"
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm git wget jre21-openjdk
        INSTALL_DIR="/usr/local/bin"
        ;;
    *)
        echo "Unsupported package manager"
        exit 1
        ;;
esac

# Cloning
git clone https://github.com/xiv3r/Burpsuite-Professional.git 
cd Burpsuite-Professional

# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
version=2026
wget -O burpsuite_pro_v$version.jar https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v$version.jar

# Execute Key Generator
echo "Starting Key loader.jar..."
(java -jar loader.jar) &

# Execute Burpsuite Professional
echo "Executing Burpsuite Professional..."
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
sudo cp burpsuitepro $INSTALL_DIR/burpsuitepro
(./burpsuitepro)
