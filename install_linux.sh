#!/bin/bash
# Burp Suite Professional - Centralized Menu

set -e

# 1. Absolute Path Resolution (Goodbye $PWD)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/sPROFFEs/Burpsuite-Professional"
LOADER_JAR="loader.jar"
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"

# 2. Centralized JVM Arguments for easy maintenance
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
    version_info=$(curl -s -L -I "$BURP_URL" | grep -i "content-disposition" | grep -o "burpsuite_pro[^;]*\.jar" | head -n1 | tr -d '\r\n')
    if [ -n "$version_info" ]; then
        printf "%s" "$version_info"
    else
        printf "%s" "burpsuite_pro_v2025.jar"
    fi
}

BURP_JAR=$(get_burp_version)

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
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$APP_DIR" 2>/dev/null || true
    fi
    echo "Launcher added to panel/menu. You can find 'BurpSuite Professional' in your applications menu."
}

function check_dependencies() {
    echo "Checking dependencies..."
    
    # Basic multi-distro support
    if command -v apt &>/dev/null; then
        PKG_MGR="sudo apt install -y"
        sudo apt update
    elif command -v pacman &>/dev/null; then
        PKG_MGR="sudo pacman -S --noconfirm"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="sudo dnf install -y"
    else
        echo "Package manager not automatically supported. Please ensure git, axel, curl, and java are installed."
        return 0
    fi

    for dep in git axel curl; do
        if ! command -v $dep &>/dev/null; then
            echo "Installing $dep..."
            $PKG_MGR $dep || { echo "Error installing $dep"; exit 1; }
        fi
    done

    if ! command -v java &>/dev/null; then
        echo "Installing Java..."
        if command -v apt &>/dev/null; then
            for java_version in openjdk-21-jre openjdk-17-jre openjdk-11-jre default-jre; do
                if sudo apt install -y $java_version 2>/dev/null; then break; fi
            done
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
    if [[ "${XDG_CURRENT_DESKTOP^^}" == *"XFCE"* ]]; then echo "xfce"
    elif [[ "${XDG_CURRENT_DESKTOP^^}" == *"GNOME"* ]]; then echo "gnome"
    elif [[ "${XDG_CURRENT_DESKTOP^^}" == *"KDE"* ]]; then echo "kde"
    else echo "unknown"
    fi
}

# 3. Proper Git usage instead of deleting and re-cloning
function sync_repository() {
    echo "Syncing repository..."
    cd "$BASE_DIR"
    
    if [ -d ".git" ]; then
        git fetch --all
        # Hard reset to the main branch (main or master) without touching untracked files like the JAR
        git reset --hard origin/$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
        git pull
    else
        echo "Directory is not a valid Git repository. Skipping Git sync..."
    fi
}

function install_burp() {
    check_dependencies
    sync_repository
    
    cd "$BASE_DIR"
    if [ ! -f "$BURP_JAR" ]; then
        echo "Downloading Burp Suite Professional..."
        axel -n 10 -o "$BURP_JAR" "$BURP_URL" || curl -L -o "$BURP_JAR" "$BURP_URL"
    else
        echo "$BURP_JAR already exists. Skipping download."
    fi
    
    if [ ! -f "$LOADER_JAR" ]; then
        echo "Error: $LOADER_JAR is missing after repository sync!"
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
    echo "Updating Burp Suite..."
    cd "$BASE_DIR"
    
    BURP_JAR=$(get_burp_version)
    echo "Latest version detected: $BURP_JAR"
    
    rm -f "$BURP_JAR"
    sync_repository
    
    echo "Downloading fresh Burp Suite Professional..."
    axel -n 10 -o "$BURP_JAR" "$BURP_URL" || curl -L -o "$BURP_JAR" "$BURP_URL"
}

function install_launcher() {
    LAUNCHER_PATH="/usr/local/bin/burpsuitepro"
    echo "Installing launcher to $LAUNCHER_PATH..."
    
    cat > burpsuitepro << EOL
#!/bin/bash
# 4. Ensuring robust execution and argument passing (\$@)
cd "${BASE_DIR}"
java ${JVM_ARGS[*]} -jar "${BASE_DIR}/${BURP_JAR}" "\$@"
EOL

    chmod +x burpsuitepro
    sudo mv burpsuitepro "$LAUNCHER_PATH"
    echo "Launcher installed. You can now run 'burpsuitepro' from anywhere."
}

function delete_launcher() {
    LAUNCHER_PATH="/usr/local/bin/burpsuitepro"
    if [ -f "$LAUNCHER_PATH" ]; then
        sudo rm "$LAUNCHER_PATH"
        echo "Launcher removed from $LAUNCHER_PATH."
    else
        echo "No launcher found at $LAUNCHER_PATH."
    fi
}

function delete_burp() {
    echo "Deleting Burp Suite files..."
    cd "$BASE_DIR"
    rm -f "$BURP_JAR" "$LOADER_JAR"
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
    if [ ! -f "$BURP_JAR" ] || [ ! -f "$LOADER_JAR" ]; then
        echo "Burp Suite or loader.jar missing. Run install first."
        exit 1
    fi
    echo "Executing Burp Suite Professional..."
    java "${JVM_ARGS[@]}" -jar "${BURP_JAR}"
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
    echo "8) Run Loader (for license activation)"
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
