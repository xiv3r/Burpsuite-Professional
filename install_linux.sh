#!/bin/bash
# Burp Suite Professional - Centralized Menu

set -Eeuo pipefail

# ==========================================
# 0. AUTO-BOOTSTRAP PARA EJECUCIÓN POR PIPE
# ==========================================
TARGET_DIR="/opt/Burpsuite-Professional"

# Si BASH_SOURCE está vacío (piped) o no estamos en el repo válido, auto-instalamos.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ ! -d ".git" ] || [ ! -f "loader.jar" ]; then
    echo "[!] Ejecución en memoria o entorno incompleto detectado."
    echo "[*] Preparando el entorno de ejecución en $TARGET_DIR..."
    
    if ! command -v git &>/dev/null; then
        if command -v apt &>/dev/null; then apt update && apt install -y git;
        elif command -v pacman &>/dev/null; then pacman -S --noconfirm git;
        elif command -v dnf &>/dev/null; then dnf install -y git;
        else echo "[X] Error: Git no está instalado. Instálalo para continuar."; exit 1;
        fi
    fi

    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        git clone https://github.com/sPROFFEs/Burpsuite-Professional.git "$TARGET_DIR"
    else
        echo "[*] El directorio $TARGET_DIR ya existe. Actualizando..."
        cd "$TARGET_DIR" && git pull || true
    fi
    
    echo "[*] Transfiriendo ejecución al repositorio local..."
    cd "$TARGET_DIR"
    chmod +x install_linux.sh
    exec bash ./install_linux.sh "$@"
fi
# ==========================================

# 1. Absolute Path Resolution (Ahora 100% seguro de que está en disco)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOADER_JAR="loader.jar"

# The CDN workaround
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"

# Centralized JVM Arguments
JVM_ARGS=(
    "--add-opens=java.desktop/javax.swing=ALL-UNNAMED"
    "--add-opens=java.base/java.lang=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED"
    "-javaagent:${BASE_DIR}/${LOADER_JAR}"
    "-noverify"
)

function get_burp_version() {
    local version_info
    version_info=$(curl -fsSL -I "$BURP_URL" | grep -i "content-disposition" | grep -Eo "burpsuite_(pro|desktop)[^;\"[:space:]]*\.jar" | head -n1 | tr -d '\r\n' || true)
    if [ -n "$version_info" ]; then
        printf "%s" "$version_info"
    else
        printf "%s" "burpsuite_desktop_latest.jar"
    fi
}

function install_panel_launcher() {
    ICON_PATH="${BASE_DIR}/burp_suite.ico"
    if [ ! -f "$ICON_PATH" ]; then
        echo "Error: Icon file $ICON_PATH not found!"
        return 1
    fi

    LAUNCHER_NAME="BurpSuite Professional"
    LAUNCHER_CMD="burpsuitepro"
    DESKTOP_FILE="burpsuite-professional.desktop"       
    APP_DIR="$HOME/.local/share/applications"
    
    # Si se ejecuta con sudo, instalar en el perfil del usuario real si existe SUDO_USER
    if [ -n "${SUDO_USER:-}" ]; then
        APP_DIR=$(su - "$SUDO_USER" -c "echo \$HOME/.local/share/applications")
    fi
    
    mkdir -p "$APP_DIR"

    cat > "$APP_DIR/$DESKTOP_FILE" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=${LAUNCHER_NAME}
Comment=Web Security Testing Tool
Exec=${LAUNCHER_CMD}
Icon=${ICON_PATH}
Terminal=false
Categories=Development;Security;
StartupNotify=true
StartupWMClass=burpsuite-pro
EOL

    chmod +x "$APP_DIR/$DESKTOP_FILE"
    if [ -n "${SUDO_USER:-}" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$APP_DIR/$DESKTOP_FILE"
    fi

    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$APP_DIR" 2>/dev/null || true
    fi
    echo "Launcher added to panel/menu. You can find 'BurpSuite Professional' in your applications menu."
}

function check_dependencies() {
    echo "Checking dependencies..."
    local PKG_MGR=""
    
    if command -v apt &>/dev/null; then
        PKG_MGR="apt install -y"
        apt update
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman -S --noconfirm"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf install -y"
    else
        echo "Package manager not automatically supported. Please ensure git, axel, curl, and java are installed."
        return 0
    fi

    for dep in git axel curl; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Installing $dep..."
            $PKG_MGR "$dep" || { echo "Error installing $dep"; exit 1; }
        fi
    done

    if ! command -v java &>/dev/null; then
        echo "Installing Java..."
        if command -v apt &>/dev/null; then
            local java_installed=false
            for java_version in openjdk-21-jre openjdk-17-jre openjdk-11-jre default-jre; do
                if apt install -y "$java_version" 2>/dev/null; then
                    java_installed=true
                    break
                fi
            done
            if [ "$java_installed" = false ]; then
                echo "Error: Could not install Java with apt."
                exit 1
            fi
        else
            $PKG_MGR jre-openjdk || $PKG_MGR java-latest-openjdk
        fi
    fi

    if ! command -v java &>/dev/null; then
        echo "Error: Could not install Java automatically. Please install Java manually (version 11 or higher)."
        exit 1
    fi
}

function detect_desktop_env() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    if [[ "${desktop^^}" == *"XFCE"* ]]; then echo "xfce"
    elif [[ "${desktop^^}" == *"GNOME"* ]]; then echo "gnome"
    elif [[ "${desktop^^}" == *"KDE"* ]]; then echo "kde"
    else echo "unknown"
    fi
}

function sync_repository() {
    echo "Syncing repository..."
    cd "$BASE_DIR"
    
    if [ -d ".git" ]; then
        local current_branch upstream
        current_branch=$(git branch --show-current)
        if [ -z "$current_branch" ]; then
            echo "Detached HEAD detected. Skipping repository sync to avoid overwriting local state."
            return 0
        fi

        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)
        if [ -z "$upstream" ]; then
            echo "No upstream configured for $current_branch. Skipping repository sync."
            return 0
        fi

        git fetch --prune
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "Local changes detected. Skipping sync to avoid overwriting your work."
            return 0
        fi

        git merge --ff-only "$upstream"
    else
        echo "Directory is not a valid Git repository. Skipping Git sync..."
    fi
}

function latest_local_jar() {
    find "$BASE_DIR" -maxdepth 1 -type f \( -name 'burpsuite_pro_*.jar' -o -name 'burpsuite_desktop_*.jar' \) -printf '%f\n' | sort -V | tail -n 1
}

function download_burp_jar() {
    local target_jar="$1"
    local temp_jar="${target_jar}.part"

    rm -f "$temp_jar"
    if axel -n 10 -o "$temp_jar" "$BURP_URL" || curl -fL -o "$temp_jar" "$BURP_URL"; then
        if [ ! -s "$temp_jar" ]; then
            echo "Error: Downloaded file is empty."
            rm -f "$temp_jar"
            return 1
        fi
        mv "$temp_jar" "$target_jar"
    else
        rm -f "$temp_jar"
        echo "Error: Download failed."
        return 1
    fi
}

function install_burp() {
    check_dependencies
    sync_repository
    
    cd "$BASE_DIR"
    
    # 2. Smart Checker: Look for ANY existing version locally
    EXISTING_JAR=$(latest_local_jar)
    
    if [ -n "$EXISTING_JAR" ]; then
        echo "Local version detected: $EXISTING_JAR. Skipping download."
    else
        echo "No local version found. Fetching latest version info from CDN..."
        BURP_JAR=$(get_burp_version)
        echo "Downloading $BURP_JAR..."
        download_burp_jar "$BURP_JAR"
    fi
    
    if [ ! -f "$LOADER_JAR" ]; then
        echo "Error: $LOADER_JAR is missing after repository sync! Verify the github repo."
        exit 1
    fi
    
    echo -e "\nInstallation complete.\n"
    echo "Starting loader.jar for initial setup..."
    (cd "$BASE_DIR" && java -jar "$LOADER_JAR") &
    echo "Starting Burp Suite Professional..."
    run_burp

    read -p "Do you want to install the global command 'burpsuitepro'? [Y/n] " install_cmd
    install_cmd=${install_cmd:-y}
    if [[ $install_cmd =~ ^[Yy] ]]; then install_launcher; fi

    desktop_env=$(detect_desktop_env)
    if [ "$desktop_env" != "unknown" ]; then
        read -p "Do you want to create a desktop shortcut for $desktop_env? [Y/n] " create_shortcut
        create_shortcut=${create_shortcut:-y}
        if [[ $create_shortcut =~ ^[Yy] ]]; then install_panel_launcher; fi
    fi
}

function update_burp() {
    echo "Checking for updates..."
    cd "$BASE_DIR"
    
    LATEST_JAR=$(get_burp_version)
    EXISTING_JAR=$(latest_local_jar)
    
    if [ "$EXISTING_JAR" == "$LATEST_JAR" ]; then
        echo "You already have the latest version ($LATEST_JAR). No update required."
        return 0
    fi
    
    echo "New version available: $LATEST_JAR"
    sync_repository
    
    echo "Downloading fresh Burp Suite Professional ($LATEST_JAR)..."
    download_burp_jar "$LATEST_JAR"
    if [ -n "$EXISTING_JAR" ] && [ "$EXISTING_JAR" != "$LATEST_JAR" ]; then
        echo "Removing old version ($EXISTING_JAR)..."
        rm -f "$EXISTING_JAR"
    fi
    echo "Update complete."
}

function install_launcher() {
    LAUNCHER_PATH="/usr/local/bin/burpsuitepro"
    local temp_launcher
    temp_launcher=$(mktemp)
    echo "Installing launcher to $LAUNCHER_PATH..."
    
    cat > "$temp_launcher" << EOL
#!/bin/bash
cd "${BASE_DIR}"
DYNAMIC_JAR=\$(find "${BASE_DIR}" -maxdepth 1 -type f \( -name 'burpsuite_pro_*.jar' -o -name 'burpsuite_desktop_*.jar' \) -printf '%f\n' | sort -V | tail -n 1)
if [ -z "\$DYNAMIC_JAR" ]; then
    echo "Error: Burp Suite JAR not found in ${BASE_DIR}"
    exit 1
fi
java ${JVM_ARGS[*]} -jar "${BASE_DIR}/\$DYNAMIC_JAR" "\$@"
EOL

    chmod +x "$temp_launcher"
    mv "$temp_launcher" "$LAUNCHER_PATH" || {
        rm -f "$temp_launcher"
        return 1
    }
    echo "Launcher installed. You can now run 'burpsuitepro' from anywhere."
}

function delete_launcher() {
    LAUNCHER_PATH="/usr/local/bin/burpsuitepro"
    if [ -f "$LAUNCHER_PATH" ]; then
        rm "$LAUNCHER_PATH"
        echo "Launcher removed from $LAUNCHER_PATH."
    else
        echo "No launcher found at $LAUNCHER_PATH."
    fi
}

function delete_burp() {
    echo "Deleting Burp Suite files..."
    cd "$BASE_DIR"
    rm -f burpsuite_pro_*.jar burpsuite_desktop_*.jar "$LOADER_JAR"
    delete_launcher
    echo "Local files and launcher deleted."
}

function run_loader() {
    cd "$BASE_DIR"
    if [ ! -f "$LOADER_JAR" ]; then
        echo "loader.jar missing. Run install first."
        exit 1
    fi
    echo "Starting $LOADER_JAR..."
    java -jar "$LOADER_JAR"
}

function run_burp() {
    cd "$BASE_DIR"
    TARGET_JAR=$(latest_local_jar)
    
    if [ -z "$TARGET_JAR" ] || [ ! -f "$LOADER_JAR" ]; then
        echo "Burp Suite or loader.jar missing. Run install first."
        exit 1
    fi
    echo "Executing Burp Suite Professional ($TARGET_JAR)..."
    java "${JVM_ARGS[@]}" -jar "${TARGET_JAR}" &
}

function pause() {
    echo -e "\nPress Enter to continue..."
    read -r
}

function menu() {
    clear
    echo -e "\nBurp Suite Professional Menu"
    echo "----------------------------------------"
    echo "1) Install Burp Suite"
    echo "2) Update Burp Suite"
    echo "3) Delete Burp Suite & Launcher"
    echo "4) Run Burp Suite"
    echo "5) Install Launcher (global command)"
    echo "6) Delete Launcher"
    echo "7) Add Panel/Menu Launcher (Desktop)"
    echo "8) Run Loader"
    echo "9) Exit"
    echo "----------------------------------------"
    read -p "Choose an option [1-9]: " opt
    case $opt in
        1) install_burp; pause; menu ;;
        2) update_burp; pause; menu ;;
        3) delete_burp; pause; menu ;;
        4) run_burp; pause; menu ;;
        5) install_launcher; pause; menu ;;
        6) delete_launcher; pause; menu ;;
        7) install_panel_launcher; pause; menu ;;
        8) run_loader; pause; menu ;;
        9) exit 0 ;;
        *) echo "Invalid option"; pause; menu ;;
    esac
}

clear
menu
