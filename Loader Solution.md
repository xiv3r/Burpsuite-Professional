\# Install Java 24 (OpenJDK)



\## Step 1: Download OpenJDK 24



Use Adoptium (Temurin builds are stable)



```

wget https://api.adoptium.net/v3/binary/latest/24/ga/linux/x64/jdk/hotspot/normal/eclipse-O openjdk24.tar.gz

```



\---



\## Step 2: Extract



```

tar-xvf openjdk24.tar.gz

```



Move it:



```

sudomv jdk-24\* /opt/java24

```



\---



\## Step 3: Set environment variables



```

nano \~/.bashrc

```



Add:



```

exportJAVA\_HOME=/opt/java24

exportPATH=$JAVA\_HOME/bin:$PATH

```



Apply:



```

source \~/.bashrc

```



\---



\## Step 4: Verify



```

java-version

```



Expected:



```

openjdk version "24"

```



\## Remove



```bash

sudo rm -rf /opt/java24

```

