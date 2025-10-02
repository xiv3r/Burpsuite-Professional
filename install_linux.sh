#!/bin/bash
# Burp Suite Professional - Centralized Menu
# Usage: ./run.sh

set -e
REPO_URL="https://github.com/xiv3r/Burpsuite-Professional.git"
REPO_DIR="$PWD"
LOADER_JAR="loader.jar"
BURP_URL="https://portswigger.net/burp/releases/download?product=pro&type=Jar"

function get_burp_version() {
    local version_info
    version_info=$(curl -s -L -I "$BURP_URL" | grep -i "content-disposition" | grep -o "burpsuite_pro[^;]*\.jar" | head -n1 | tr -d '\r\n')
    if [ -n "$version_info" ]; then
        printf "%s" "$version_info"
    else
        printf "%s" "burpsuite_pro_v2025.jar"  # fallback version
    fi
}

BURP_JAR=$(get_burp_version)

function install_panel_launcher() {
    ICON_PATH="$PWD/burp_suite.ico"
    if [ ! -f "$ICON_PATH" ]; then
        echo "Error: Icon file $ICON_PATH not found!"
        return 1
    fi

    LAUNCHER_NAME="BurpSuite Professional"
    LAUNCHER_CMD="burpsuitepro"
    DESKTOP_FILE="burpsuite-professional.desktop"       
    # XFCE4 & GNOME (ambos usan ~/.local/share/applications)
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
    update-desktop-database "$APP_DIR" 2>/dev/null || true
    echo "Launcher added to panel/menu for XFCE4 and GNOME. You can find 'BurpSuite Professional' in your applications menu."
}

function check_dependencies() {
    echo "Installing Dependencies..."
    sudo apt update

    # Install basic dependencies
    for dep in git axel curl; do
        if ! command -v $dep &>/dev/null; then
            echo "Installing $dep..."
            sudo apt install -y $dep || {
                echo "Error installing $dep"
                exit 1
            }
        fi
    done

    # Try to install Java if not present
    if ! command -v java &>/dev/null; then
        echo "Installing Java..."
        # Try different Java versions in order of preference
        for java_version in openjdk-21-jre openjdk-17-jre openjdk-11-jre default-jre; do
            if sudo apt install -y $java_version 2>/dev/null; then
                echo "Successfully installed $java_version"
                break
            fi
        done
    fi

    # Final verification
    if ! command -v java &>/dev/null; then
        echo "Error: Could not install Java. Please install Java manually (version 11 or higher)"
        exit 1
    fi

    # Show installed Java version
    echo "Using Java version:"
    java -version
}

function detect_desktop_env() {
    if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
        echo "xfce"
    elif [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
        echo "gnome"
    else
        echo "unknown"
    fi
}

function sync_repository() {
    SCRIPT_NAME="install_linux.sh"
    
    # Backup Burp JAR if it exists
    if [ -f "$BURP_JAR" ]; then
        echo "Backing up $BURP_JAR..."
        cp "$BURP_JAR" "${BURP_JAR}.backup"
    fi

    # Backup the install script itself
    if [ -f "$SCRIPT_NAME" ]; then
        echo "Backing up $SCRIPT_NAME..."
        cp "$SCRIPT_NAME" "${SCRIPT_NAME}.backup"
    fi

    echo "Cloning fresh repository..."
    # Remove everything except backups
    find . -not -name '*.backup' -type f -exec rm -f {} +
    rm -rf .git

    git clone "$REPO_URL" temp_repo
    cp -rf temp_repo/* temp_repo/.git .
    rm -rf temp_repo

    # Restore the install script
    if [ -f "${SCRIPT_NAME}.backup" ]; then
        echo "Restoring $SCRIPT_NAME..."
        mv "${SCRIPT_NAME}.backup" "$SCRIPT_NAME"
        chmod +x "$SCRIPT_NAME"
    fi

    # Restore Burp JAR if it was backed up
    if [ -f "${BURP_JAR}.backup" ]; then
        echo "Restoring $BURP_JAR from backup..."
        mv "${BURP_JAR}.backup" "$BURP_JAR"
    fi
}

function install_burp() {
    check_dependencies
    
    # Clone fresh repository
    sync_repository
    
    # Check and download JAR if needed
    if [ ! -f "$BURP_JAR" ]; then
        echo "Downloading Burp Suite Professional..."
        axel -o "$BURP_JAR" "$BURP_URL"
    else
        echo "$BURP_JAR already exists. Skipping download."
    fi
    
    # Verify loader.jar exists
    if [ ! -f "$LOADER_JAR" ]; then
        echo "Error: loader.jar is missing after repository sync!"
        exit 1
    fi
    echo "\nInstallation complete.\n"
    
    echo "Starting loader.jar for initial setup..."
    (java -jar "$LOADER_JAR") &
    echo "Starting Burp Suite Professional..."
    run_burp

    read -p "Do you want to install the global command 'burpsuitepro'? [Y/n] " install_cmd
    install_cmd=${install_cmd:-y}
    if [[ $install_cmd =~ ^[Yy] ]]; then
        install_launcher
    fi

    desktop_env=$(detect_desktop_env)
    if [ "$desktop_env" != "unknown" ]; then
        read -p "Do you want to create a desktop shortcut for $desktop_env? [Y/n] " create_shortcut
        create_shortcut=${create_shortcut:-y}
        if [[ $create_shortcut =~ ^[Yy] ]]; then
            install_panel_launcher
        fi
    fi
}

function update_burp() {
    echo "Updating Burp Suite..."
    
    # Get latest version name
    BURP_JAR=$(get_burp_version)
    echo "Latest version: $BURP_JAR"
    
    # Always remove the JAR file first
    rm -f "$BURP_JAR"
    
    # Update repository files
    sync_repository
    
    # Always download fresh JAR
    echo "Downloading fresh Burp Suite Professional..."
    axel -o "$BURP_JAR" "$BURP_URL"
}


function install_launcher() {
    LAUNCHER_PATH="/usr/local/bin/burpsuitepro"
    echo "Installing launcher to $LAUNCHER_PATH..."
    cat > burpsuitepro << EOL
#!/bin/bash
cd "$PWD"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:"$PWD/$LOADER_JAR" \
     -noverify \
     -jar "$PWD/$BURP_JAR"
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
    rm -f "$BURP_JAR" "$LOADER_JAR"
    delete_launcher
    echo "Deleted $BURP_JAR, $LOADER_JAR, and launcher."
}

function run_loader() {
    if [ ! -f "$LOADER_JAR" ]; then
        echo "loader.jar missing. Run install first."
        exit 1
    fi
    echo "Starting Key loader.jar..."
    java -jar "$LOADER_JAR"
}

function run_burp() {
    if [ ! -f "$BURP_JAR" ] || [ ! -f "$LOADER_JAR" ]; then
        echo "Burp Suite or loader.jar missing. Run install first."
        exit 1
    fi
    JAVA_OPTS="--add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$PWD/$LOADER_JAR -noverify -jar $PWD/$BURP_JAR"
    echo "Executing Burp Suite Professional..."
    java $JAVA_OPTS
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
    echo "7) Add Panel/Menu Launcher (XFCE4/GNOME)"
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
