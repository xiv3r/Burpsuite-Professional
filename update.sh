#!/bin/bash

# Remove old files
echo "Removing Old Files..."
sudo rm -f /bin/burpsuitepro

# Installing Dependencies
echo "Installing Dependencies..."
sudo apt update
sudo apt install git wget openjdk-21-jre -y

# Cloning
git clone https://github.com/xiv3r/Burpsuite-Professional.git 
cd Burpsuite-Professional

# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
version=2025
wget -O burpsuite_pro_v$version.jar https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v$version.jar

# Execute Key Generator
echo "Starting Key loader.jar..."
(java -jar loader.jar) &

# Execute Burpsuite Professional
echo "Executing Burpsuite Professional..."
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
cp burpsuitepro /bin/burpsuitepro
(./burpsuitepro)
