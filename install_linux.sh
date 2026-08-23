#!/bin/bash
# Burp Suite Professional - Modular Architecture Installer

set -e

# ==========================================
# 1. STRICT ENVIRONMENT VALIDATION
# ==========================================
if [ "$EUID" -ne 0 ]; then
    clear
    echo "[!] PRIVILEGE ERROR"
    echo "========================================"
    echo "This script architecture requires modifying /opt/ and /usr/local/bin/."
    echo "Root execution is mandatory. Use the following command:"
    echo "wget -qO- https://raw.githubusercontent.com/sPROFFEs/Burpsuite-Professional/main/install_linux.sh | sudo bash"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

REPO_URL="https://github.com/sPROFFEs/Burpsuite-Professional.git"
INSTALL_DIR="/opt/Burpsuite-Professional"
LOADER_JAR="loader.jar"
BIN_PATH="/usr/local/bin/burpsuitepro"
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"
TARGET_JAR="burpsuite_pro_latest.jar"

# ==========================================
# 2. CORE MODULES
# ==========================================
function install_dependencies() {
    echo ">> Installing base dependencies..."
    if command -v apt &>/dev/null; then
        apt update -y -q && apt install -y -q git curl wget axel openjdk-21-jre
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm git curl wget axel jre-openjdk
    elif command -v dnf &>/dev/null; then
        dnf install -y git curl wget axel java-latest-openjdk
    else
        echo "[!] Package manager not supported automatically. Install Git, Curl, Wget, and Java 21."
    fi
}

function clone_repo() {
    echo ">> Preparing Installation Directory (/opt/)..."
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        git clone "$REPO_URL" "$INSTALL_DIR"
    else
        echo ">> Repository detected. Updating..."
        git -C "$INSTALL_DIR" fetch --all
        git -C "$INSTALL_DIR" reset --hard origin/main
    fi
    chmod -R 755 "$INSTALL_DIR"
}

# ==========================================
# 3. LAUNCHER MODULES (ON DEMAND)
# ==========================================
function create_global_launcher() {
    echo ">> Building Global Command (burpsuitepro)..."
    
    cat > "$BIN_PATH" << EOF
#!/bin/bash
cd "${INSTALL_DIR}"
nohup java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \\
     --add-opens=java.base/java.lang=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \\
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \\
     -javaagent:${INSTALL_DIR}/${LOADER_JAR} \\
     -noverify \\
     -jar ${INSTALL_DIR}/${TARGET_JAR} "\$@" > /dev/null 2>&1 &
EOF

    chmod +x "$BIN_PATH"
    echo "[+] Global command created at $BIN_PATH"
}

function create_desktop_shortcut() {
    echo ">> Creating desktop shortcut..."
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
    echo "[+] Desktop shortcut created in the applications menu."
}

function delete_launchers() {
    echo ">> Removing system launchers..."
    rm -f "$BIN_PATH"
    rm -f "${USER_HOME}/.local/share/applications/burpsuite-professional.desktop"
    echo "[+] Launchers purged."
}

# ==========================================
# 4. EXECUTION LOGIC (PRIVILEGE DROP)
# ==========================================
function execute_keygen() {
    if [ ! -f "${INSTALL_DIR}/${LOADER_JAR}" ]; then
        echo "[!] Error: ${LOADER_JAR} does not exist. Run the main installation first."
        return
    fi
    echo ">> Starting Loader as user $REAL_USER..."
    sudo -H -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}" java -jar "${INSTALL_DIR}/${LOADER_JAR}"
}

function execute_burp() {
    if [ ! -f "$BIN_PATH" ]; then
        echo "[!] Error: The launcher does not exist. Create it using the menu option."
        return
    fi
    echo ">> Starting Burp Suite as user $REAL_USER..."
    sudo -H -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}" "$BIN_PATH"
}

# ==========================================
# 5. MASTER FLOWS
# ==========================================
function install_full() {
    install_dependencies
    clone_repo
    
    echo ">> Downloading the latest Pro version from PortSwigger..."
    wget -q --show-progress -O "${INSTALL_DIR}/${TARGET_JAR}" "$BURP_URL"
    
    # Auto-generate default launchers during full installation
    create_global_launcher
    create_desktop_shortcut
    
    echo -e "\n[+] Deployment completed."
    echo "[*] Opening windows for activation under the $REAL_USER profile..."
    execute_keygen &
    sleep 2
    execute_burp &
}

function uninstall_all() {
    echo ">> Purging total system installation..."
    rm -rf "$INSTALL_DIR"
    delete_launchers
    echo "[+] System clean."
}

function pause() {
    echo -e "\nPress Enter to continue..."
    read -r < /dev/tty
}

# ==========================================
# 6. MAIN MENU
# ==========================================
function show_menu() {
    while true; do
        clear
        echo "========================================"
        echo " BURP SUITE PRO - KALI LINUX MANAGER"
        echo "========================================"
        echo "1) Full Install / Update"
        echo "2) Launch Burp Suite"
        echo "3) Launch Keygen (Manual Activation)"
        echo "----------------------------------------"
        echo "4) Install Global Launcher (Command)"
        echo "5) Install Desktop Shortcut"
        echo "6) Remove Launchers"
        echo "----------------------------------------"
        echo "7) Purge Total Installation"
        echo "8) Exit"
        echo "========================================"
        read -p "Choose an option [1-8]: " opt < /dev/tty
        case $opt in
            1) install_full; pause ;;
            2) execute_burp; pause ;;
            3) execute_keygen; pause ;;
            4) create_global_launcher; pause ;;
            5) create_desktop_shortcut; pause ;;
            6) delete_launchers; pause ;;
            7) uninstall_all; pause ;;
            8) exit 0 ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

show_menu
