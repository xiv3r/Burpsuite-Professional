#!/bin/bash

  # Execute Keygenerator
    echo 'Starting Keygenerator'
    (java -jar keygen.jar) &
    sleep 2s

  # Execute Burp Suite Professional with Keyloader
    echo 'Executing Burp Suite Professional with Keyloader'
    echo "java --illegal-access=permit -Dfile.encoding=utf-8 -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v2022.8.5.jar &" > Burp
    chmod +x Burp
    cp Burp /bin/Burp 
    (./Burp)
else
    echo "Execute Command as Root User"
exit
