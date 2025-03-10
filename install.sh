#!/bin/bash

# Installing Dependencies
echo "Installing Dependencies..."
sudo apt update
sudo apt install git wget openjdk-21-jre openjdk-22-jre openjdk-23-jre -y

# Cloning
git clone https://github.com/xiv3r/Burpsuite-Professional.git 
cd Burpsuite-Professional

# Download Burpsuite Professional Latest.
Link="https://portswigger-cdn.net/burp/releases/download?product=pro&version=2025.1.4&type=Jar"

# Extract the version from the Link
version=$(echo "$Link" | grep -oP '(?<=version=)[^&]+')

# Download Burpsuite Professional
echo "Downloading Burpsuite Professional v$version ..."
wget "$Link" -O burpsuite_pro_v$version.jar --quiet --show-progress

# Execute Key Generator
echo "Starting Key loader.jar..."
(java -jar loader.jar) &

# Execute Burpsuite Professional
echo "Executing Burpsuite Professional..."
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
cp burpsuitepro /bin/burpsuitepro
(./burpsuitepro)
