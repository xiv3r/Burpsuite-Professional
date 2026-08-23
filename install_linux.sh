#!/bin/bash
# Burp Suite Professional - Ultimate Installer

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Error: Debes ejecutar este script como root."
    echo "[!] Comando: wget -qO- https://raw.github.../install.sh | sudo bash"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
INSTALL_DIR="/opt/Burpsuite-Professional"

echo ">> 1. Instalando Dependencias..."
apt update -y -q
apt install -y -q git wget curl openjdk-21-jre

echo ">> 2. Preparando el Directorio de Instalación (/opt/)..."
rm -rf "$INSTALL_DIR"
git clone https://github.com/sPROFFEs/Burpsuite-Professional.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ">> 3. Descargando la ÚLTIMA versión de Burp Suite..."
# En lugar de descargar una versión vieja de GitHub, sacamos la última de PortSwigger
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"
BURP_JAR=$(curl -fsSL -D - -o /dev/null "$BURP_URL" | grep -i "content-disposition" | grep -Eo "burpsuite_(pro|desktop)[^;\"[:space:]]*\.jar" | head -n1 | tr -d '\r\n' || echo "burpsuite_desktop_latest.jar")
wget -q --show-progress -O "$BURP_JAR" "$BURP_URL"

echo ">> 4. Creando el Comando Global (burpsuitepro)..."
# Usamos la lógica de una sola línea de xiv3r pero apuntando siempre a /opt/
cat > /usr/local/bin/burpsuitepro << EOF
#!/bin/bash
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:${INSTALL_DIR}/loader.jar \
     -noverify \
     -jar ${INSTALL_DIR}/${BURP_JAR} "\$@"
EOF

chmod +x /usr/local/bin/burpsuitepro
chmod -R 755 "$INSTALL_DIR"

echo ">> 5. Ejecutando Entorno para Activación..."
# Ejecutamos con el usuario REAL (kali), no como root, para que la licencia se guarde bien
sudo -H -u "$REAL_USER" java -jar "${INSTALL_DIR}/loader.jar" &
sleep 2
sudo -H -u "$REAL_USER" /usr/local/bin/burpsuitepro &

echo -e "\n[+] Instalación completada. Haz la activación manual ahora."
echo "[+] A partir de ahora, solo tienes que escribir 'burpsuitepro' en la terminal."
