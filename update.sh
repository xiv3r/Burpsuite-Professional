#!/bin/bash

# Remove old files
echo "Removing Old Files..."

sudo rm -rf /bin/burpsuitepro

# Installing Dependencies
echo "Installing Dependencies..."

sudo apt update
sudo apt install git wget openjdk-21-jre -y

# Cloning
git clone https://github.com/xiv3r/Burpsuite-Professional.git 

cd Burpsuite-Professional

# Download Burpsuite Professional Latest.

latest_version=$(curl -s https://portswigger.net/burp/releases/professional/latest | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
echo -e "\n\t\tDownloading Latest Burp Suite Professional version $latest_version"
# Download the file
curl -L "https://portswigger-cdn.net/burp/releases/download?product=pro&version=$latest_version&type=Jar" \
     --output "burpsuite_pro_v$latest_version.jar"
echo -e "\nBurp Suite Professional v$latest_version is Downloaded.\n"

# Download Burpsuite Professional
echo "Downloading Burpsuite Professional v$latest_version"
wget "$Link" -O burpsuite_pro_v$latest_version.jar --quiet --show-progress

# Execute Key Generator.
echo "Starting Key loader.jar..."

(java -jar loader.jar) &

# Execute Burp Suite Professional
echo "Executing Burpsuite Professional..."

echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
cp burpsuitepro /bin/burpsuitepro
(./burpsuitepro)
