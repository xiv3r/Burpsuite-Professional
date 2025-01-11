#!/bin/bash

# Remove old files
echo "Removing Old Files..."

sudo rm -rf /usr/local/bin/burpsuitepro

# Installing Dependencies
echo "Installing Dependencies..."

sudo apt update
sudo apt install git wget openjdk-21-jre -y

# Cloning (alleen nodig als je opnieuw alles wilt binnenhalen)
#git clone https://github.com/xiv3r/Burpsuite-Professional.git 

cd /home/kali/Burpsuite-Professional

# Download Burpsuite Professional Latest (Link en version nummers aanpassen naar nieuwere versie) - https://portswigger.net/burp/pro en ga naar downloads.
Link="https://portswigger-cdn.net/burp/releases/download?product=pro&version=2024.11.2&type=Jar"
version="2024.11.2"

echo "Downloading Burpsuite Professional v$version ..."

wget "$Link" -O burpsuite_pro_v$version.jar --quiet --show-progress

# Execute Key Generator.
echo "Starting Key loader.jar..."

(java -jar loader.jar) &

# Execute Burp Suite Professional
echo "Executing Burpsuite Professional..."

echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
sudo cp burpsuitepro /usr/local/bin/burpsuitepro
(./burpsuitepro)
