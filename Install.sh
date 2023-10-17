#!/bin/bash

  # Download Burp Suite Profesional Latest Version
    echo 'Downloading Burp Suite Professional v2022.8.5 ....'
    wget "https://portswigger-cdn.net/burp/releases/download?product=pro&version=2022.8.5&type=Jar" -O burpsuite_pro_v2022.8.5.jar --quiet --show-progress

  # Execute Key Generator
    echo 'Starting Keygenerator'
    (java -jar keygen.jar) &
    sleep 2s
    
  # Execute Burp Suite Professional with Keyloader
    echo 'Executing Burp Suite Professional with Keyloader'
    echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v2022.8.5.jar &" > Burp
    chmod +x Burp
    cp Burp /bin/Burp 
    (./Burp)
