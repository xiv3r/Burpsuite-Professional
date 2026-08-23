#!/bin/bash
# Burp Suite Professional - Modular Architecture Installer

set -e

# ==========================================
# 1. VALIDACIÓN ESTRICTA DE ENTORNO
# ==========================================
if [ "$EUID" -ne 0 ]; then
    clear
    echo "[!] ERROR DE PRIVILEGIOS"
    echo "========================================"
    echo "La arquitectura de este script exige modificar /opt/ y /usr/local/bin/."
    echo "Ejecución obligatoria como root. Usa el siguiente comando:"
    echo "wget -qO- https://raw.githubusercontent.com/.../install_linux.sh | sudo bash"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

REPO_URL="https://github.com/sPROFFEs/Burpsuite-Professional.git"
INSTALL_DIR="/opt/Burpsuite-Professional"
LOADER_JAR="loader.jar"
BIN_PATH="/usr/local/bin/burpsuitepro"
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"

# ==========================================
# 2. MÓDULOS DEL NÚCLEO
# ==========================================
function install_dependencies() {
    echo ">> Instalando dependencias base..."
    if command -v apt &>/dev/null; then
        apt update -y -q && apt install -y -q git curl wget axel openjdk-21-jre
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm git curl wget axel jre-openjdk
    elif command -v dnf &>/dev/null; then
        dnf install -y git curl wget axel java-latest-openjdk
    else
        echo "[!] Gestor de paquetes no soportado automáticamente. Instala Git, Curl, Wget y Java 21."
    fi
}

function clone_repo() {
    echo ">> Preparando el Directorio de Instalación (/opt/)..."
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        git clone "$REPO_URL" "$INSTALL_DIR"
    else
        echo ">> Repositorio detectado. Actualizando..."
        git -C "$INSTALL_DIR" fetch --all
        git -C "$INSTALL_DIR" reset --hard origin/main
    fi
    chmod -R 755 "$INSTALL_DIR"
}

function get_latest_cdn_version() {
    curl -fsSL -D - -o /dev/null "$BURP_URL" | grep -i "content-disposition" | grep -Eo "burpsuite_(pro|desktop)[^;\"[:space:]]*\.jar" | head -n1 | tr -d '\r\n' || echo "burpsuite_desktop_latest.jar"
}

function get_local_jar() {
    find "$INSTALL_DIR" -maxdepth 1 -type f \( -name 'burpsuite_pro_*.jar' -o -name 'burpsuite_desktop_*.jar' \) -printf '%f\n' | sort -V | tail -n 1
}

# ==========================================
# 3. MÓDULOS DE LANZADORES (A DEMANDA)
# ==========================================
function create_global_launcher() {
    local target_jar
    target_jar=$(get_local_jar)

    if [ -z "$target_jar" ]; then
        echo "[!] Error: No se encontró el JAR de Burp en $INSTALL_DIR. Instala primero."
        return 1
    fi

    echo ">> Construyendo el Comando Global (burpsuitepro)..."
    
    cat > "$BIN_PATH" << EOF
#!/bin/bash
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \\
     --add-opens=java.base/java.lang=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \\
     -javaagent:${INSTALL_DIR}/${LOADER_JAR} \\
     -noverify \\
     -jar ${INSTALL_DIR}/${target_jar} "\$@"
EOF

    chmod +x "$BIN_PATH"
    echo "[+] Comando global creado en $BIN_PATH"
}

function create_desktop_shortcut() {
    echo ">> Creando acceso directo gráfico..."
    local app_dir="${USER_HOME}/.local/share/applications"
    local desktop_file="$app_dir/burpsuite-professional.desktop"
    local icon_path="${INSTALL_DIR}/burp_suite.ico"

    mkdir -p "$app_dir"

    cat > "$desktop_file" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=BurpSuite Professional
Comment=Web Security Testing Tool
Exec=${BIN_PATH}
Icon=${icon_path}
Terminal=false
Categories=Development;Security;
StartupNotify=true
StartupWMClass=burpsuite-pro
EOL

    chmod +x "$desktop_file"
    chown "$REAL_USER:$REAL_USER" "$desktop_file"

    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$app_dir" 2>/dev/null || true
    fi
    echo "[+] Acceso directo creado en el menú de aplicaciones."
}

function delete_launchers() {
    echo ">> Eliminando lanzadores del sistema..."
    rm -f "$BIN_PATH"
    rm -f "${USER_HOME}/.local/share/applications/burpsuite-professional.desktop"
    echo "[+] Lanzadores purgados."
}

# ==========================================
# 4. LÓGICA DE EJECUCIÓN (PRIVILEGE DROP)
# ==========================================
function execute_keygen() {
    if [ ! -f "${INSTALL_DIR}/${LOADER_JAR}" ]; then
        echo "[!] Error: ${LOADER_JAR} no existe. Ejecuta la instalación principal."
        return
    fi
    echo ">> Arrancando Loader como usuario $REAL_USER..."
    sudo -H -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}" java -jar "${INSTALL_DIR}/${LOADER_JAR}"
}

function execute_burp() {
    if [ ! -f "$BIN_PATH" ]; then
        echo "[!] Error: El lanzador no existe. Créalo usando la opción del menú."
        return
    fi
    echo ">> Arrancando Burp Suite como usuario $REAL_USER..."
    sudo -H -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}" "$BIN_PATH"
}

# ==========================================
# 5. FLUJOS MAESTROS
# ==========================================
function install_full() {
    install_dependencies
    clone_repo
    
    local latest
    latest=$(get_latest_cdn_version)
    local local_jar
    local_jar=$(get_local_jar)
    
    if [ "$latest" == "$local_jar" ]; then
        echo ">> Ya posees la última versión ($latest). Saltando descarga."
    else
        echo ">> Descargando $latest desde PortSwigger..."
        wget -q --show-progress -O "${INSTALL_DIR}/${latest}" "$BURP_URL"
        if [ -n "$local_jar" ] && [ "$local_jar" != "$latest" ]; then 
            rm -f "${INSTALL_DIR}/${local_jar}"
        fi
    fi

    # Auto-generar lanzadores por defecto durante la instalación completa
    create_global_launcher
    create_desktop_shortcut
    
    echo -e "\n[+] Despliegue completado."
    echo "[*] Abriendo ventanas para activación en el perfil de $REAL_USER..."
    execute_keygen &
    sleep 2
    execute_burp &
}

function uninstall_all() {
    echo ">> Purgando instalación total del sistema..."
    rm -rf "$INSTALL_DIR"
    delete_launchers
    echo "[+] Sistema limpio."
}

function pause() {
    echo -e "\nPulsa Enter para continuar..."
    read -r < /dev/tty
}

# ==========================================
# 6. MENÚ PRINCIPAL
# ==========================================
function show_menu() {
    while true; do
        clear
        echo "========================================"
        echo " BURP SUITE PRO - KALI LINUX MANAGER"
        echo "========================================"
        echo "1) Instalar / Actualizar Completo"
        echo "2) Lanzar Burp Suite"
        echo "3) Lanzar Keygen (Activación Manual)"
        echo "----------------------------------------"
        echo "4) Instalar Lanzador Global (Comando)"
        echo "5) Instalar Acceso Directo (Escritorio)"
        echo "6) Eliminar Lanzadores"
        echo "----------------------------------------"
        echo "7) Purgar Instalación Total"
        echo "8) Salir"
        echo "========================================"
        read -p "Elige una opción [1-8]: " opt < /dev/tty
        case $opt in
            1) install_full; pause ;;
            2) execute_burp; pause ;;
            3) execute_keygen; pause ;;
            4) create_global_launcher; pause ;;
            5) create_desktop_shortcut; pause ;;
            6) delete_launchers; pause ;;
            7) uninstall_all; pause ;;
            8) exit 0 ;;
            *) echo "Opción inválida."; pause ;;
        esac
    done
}

show_menu
