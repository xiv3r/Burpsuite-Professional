#!/bin/bash

set -e  # Stop on error

echo "[+] Updating package list..."
sudo apt update -y

# Fonction pour vérifier si une commande est dispo
install_if_missing() {
    local cmd="$1"
    local pkg="$2"
    
    if ! command -v "$cmd" &>/dev/null; then
        echo "[+] Installing $pkg..."
        sudo apt install -y "$pkg"
    else
        echo "[✓] $pkg already installed."
    fi
}

# Vérifie et installe chaque dépendance séparément
install_if_missing git git
install_if_missing axel axel
install_if_missing java java-common
install_if_missing javac openjdk-21-jdk

# Clonage du repo
if [ ! -d "Burpsuite-Professional" ]; then
    echo "[+] Cloning repository..."
    git clone https://github.com/xiv3r/Burpsuite-Professional.git 
else
    echo "[✓] Repository already cloned."
fi

cd Burpsuite-Professional

# Télécharger Burpsuite
version=2025
output="burpsuite_pro_v$version.jar"
url="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"

if [ ! -f "$output" ]; then
    echo "[+] Downloading Burpsuite Professional..."
    axel -n 8 "$url" -o "$output"
else
    echo "[✓] Burpsuite JAR already downloaded."
fi

# Lancer le keygen
echo "[+] Starting loader.jar..."
(java -jar loader.jar) &

# Créer le lanceur
echo "[+] Creating launcher script..."
cat <<EOF > burpsuitepro
#!/bin/bash
java \\
--add-opens=java.desktop/javax.swing=ALL-UNNAMED \\
--add-opens=java.base/java.lang=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \\
-javaagent:$(pwd)/loader.jar \\
-noverify -jar $(pwd)/burpsuite_pro_v$version.jar
EOF

chmod +x burpsuitepro
sudo cp burpsuitepro /usr/local/bin/burpsuitepro

# Lancer Burp
echo "[+] Launching BurpSuite Professional..."
burpsuitepro
