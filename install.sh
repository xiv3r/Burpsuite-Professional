#!/bin/bash

# Installing Dependencies
   echo 'Installing Dependencies...'
 
   sudo apt install git wget openjdk-21-jre -y

# Cloning
   git clone https://github.com/xiv3r/Burpsuite-Professional.git 
 
# Download Burpsuite Professional Latest.
  echo 'Downloading Burpsuite Professional Latest...'
   
  cd Burpsuite-Professional
    
    # URL containing the version
Link="https://portswigger-cdn.net/burp/releases/download?product=pro&version=2024.11.1&type=jar"

# Extract the version from the URL using grep and cut
version=$(echo "$Link" | grep -oP "version=\K[0-9.]+")

# Download the file with the version in the output filename
wget "$Link" -O burpsuite_pro_v$version.jar --quiet --show-progress

# Execute Key Generator.
    echo 'Starting Key loader.jar...'
    (java -jar loader.jar) &
    sleep 2s

# Execute Burp Suite Professional
    echo 'Executing Burpsuite Professional...'
    echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
    chmod +x burpsuitepro
    cp burpsuitepro /bin/burpsuitepro
    (./burpsuitepro)
