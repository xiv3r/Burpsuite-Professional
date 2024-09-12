#!/bin/bash

# Installing Dependencies
   echo 'Installing Dependencies'
   sudo apt update ; sudo apt install curl git wget openjdk-17-jdk openjdk-17-jre openjdk-23-jdk openjdk-23-jre -y

# Cloning
   echo 'Cloning Xiv3r Burpsuite Professional'
   git clone https://github.com/xiv3r/Burpsuite-Professional.git     
   cd /home/*/Burpsuite-Professional
 
# Download Burpsuite Professional Latest.
    echo 'Downloading Burpsuite Professional Latest...'
    mkdir -p /usr/share/burpsuitepro
    cp -r /home/*/Burpsuite-Professional/loader.jar /usr/share/burpsuitepro
    cd /usr/share/burpsuitepro
    html=$(curl -s https://portswigger.net/burp/releases)
    version=$(echo $html | grep -Po '(?<=/burp/releases/professional-community-)[0-9]+\-[0-9]+\-[0-9]+' | head -n 1)
    Link="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=&"
    echo $version
    wget "$Link" -O burpsuite_pro_v$version.jar --quiet --show-progress

# Execute Key Generator.
    echo 'Starting Key Generator'
    (java -jar /home/*/Burpsuite-Professional/loader.jar) &
    sleep 2s

# Execute Burp Suite Professional
    echo 'Executing Burpsuite Professional with Key Generator'
    echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
    chmod +x burpsuitepro
    cp burpsuitepro /bin/burpsuitepro
    (./burpsuitepro)
