#!/bin/bash

    # execute Keygenerator
    echo 'Starting Keygenerator'
    (java -jar keygen.jar) &
    sleep 2s

  # Execute Burp Suite Professional with Keyloader
    echo 'Executing Burp Suite Professional with Keyloader'
    echo "java --illegal-access=permit -Dfile.encoding=utf-8 -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v2022.8.5.jar &" > burp1
    chmod +x burp1
    cp burp1 /bin/burp1 
    (./burp1)
else
    echo "Execute Command as Root User"
    exit
fi
