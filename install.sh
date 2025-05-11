#!/bin/bash
#
# Burpsuite Professional Installer Script
# Enhanced version with cross-distro support and error handling
#

# Set up error handling
set -e
trap 'echo "Error occurred at line $LINENO. Command: $BASH_COMMAND"' ERR

# Terminal colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display messages
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to detect package manager and install packages
install_packages() {
    local packages=("$@")
    
    if command_exists apt; then
        log "Detected apt package manager (Debian/Ubuntu)"
        sudo apt update || log_warning "Failed to update package lists"
        sudo apt install -y "${packages[@]}" || log_error "Failed to install packages with apt"
    elif command_exists dnf; then
        log "Detected dnf package manager (Fedora/RHEL)"
        sudo dnf check-update || log_warning "Failed to update package lists"
        sudo dnf install -y "${packages[@]}" || log_error "Failed to install packages with dnf"
    elif command_exists yum; then
        log "Detected yum package manager (CentOS/RHEL)"
        sudo yum check-update || log_warning "Failed to update package lists" 
        sudo yum install -y "${packages[@]}" || log_error "Failed to install packages with yum"
    elif command_exists pacman; then
        log "Detected pacman package manager (Arch Linux)"
        sudo pacman -Sy --noconfirm "${packages[@]}" || log_error "Failed to install packages with pacman"
    elif command_exists zypper; then
        log "Detected zypper package manager (openSUSE)"
        sudo zypper refresh || log_warning "Failed to update package lists"
        sudo zypper install -y "${packages[@]}" || log_error "Failed to install packages with zypper"
    elif command_exists apk; then
        log "Detected apk package manager (Alpine Linux)"
        sudo apk update || log_warning "Failed to update package lists"
        sudo apk add "${packages[@]}" || log_error "Failed to install packages with apk"
    else
        log_error "Could not detect package manager. Please install the following packages manually: ${packages[*]}"
        exit 1
    fi
}

# Function to check Java version
check_java() {
    if ! command_exists java; then
        log_error "Java is not installed. Please install Java manually and try again."
        log "Recommended: Java 11 or newer"
        return 1
    fi
    
    # Get Java version
    java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed 's/^1\.//' | cut -d'.' -f1)
    log "Detected Java version: $java_version"
    
    if [[ -z "$java_version" || "$java_version" -lt 11 ]]; then
        log_warning "Burpsuite Professional works best with Java 11 or newer."
        log "Current Java version: $(java -version 2>&1 | head -1)"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation aborted by user."
            exit 1
        fi
    fi
    
    return 0
}

# Function to check if axel is installed, otherwise use wget or curl
check_download_tool() {
    if command_exists axel; then
        download_cmd="axel -a -n 10"
        log "Using axel for downloading"
    elif command_exists wget; then
        download_cmd="wget -O"
        log "Using wget for downloading"
    elif command_exists curl; then
        download_cmd="curl -L -o"
        log "Using curl for downloading"
    else
        log_error "No download tool found. Please install axel, wget, or curl."
        return 1
    fi
    
    return 0
}

# Main installation process
main() {
    log "Starting Burpsuite Professional installation..."
    
    # Create a directory for installation
    install_dir="$HOME/burpsuite_pro"
    mkdir -p "$install_dir"
    cd "$install_dir" || { log_error "Failed to create installation directory"; exit 1; }
    log "Working directory: $(pwd)"
    
    # Check for required packages
    log "Checking for required packages..."
    required_packages=()
    
    if ! command_exists git; then
        required_packages+=("git")
    fi
    
    if ! command_exists axel && ! command_exists wget && ! command_exists curl; then
        # Prefer axel, but can fall back to wget or curl
        if command_exists apt || command_exists dnf || command_exists yum; then
            required_packages+=("axel")
        elif command_exists pacman; then
            required_packages+=("axel")
        else
            required_packages+=("wget")
        fi
    fi
    
    if ! command_exists java; then
        # Package names vary by distribution
        if command_exists apt; then
            required_packages+=("openjdk-17-jre" "default-jre")
        elif command_exists dnf || command_exists yum; then
            required_packages+=("java-17-openjdk")
        elif command_exists pacman; then
            required_packages+=("jre-openjdk")
        elif command_exists zypper; then
            required_packages+=("java-17-openjdk")
        elif command_exists apk; then
            required_packages+=("openjdk17-jre")
        fi
    fi
    
    # Install required packages if any
    if [ ${#required_packages[@]} -gt 0 ]; then
        log "Installing required packages: ${required_packages[*]}"
        install_packages "${required_packages[@]}"
    else
        log "All required packages are already installed."
    fi
    
    # Check Java installation
    check_java || exit 1
    
    # Check download tool
    check_download_tool || exit 1
    
    # Clone the repository
    log "Cloning the Burpsuite-Professional repository..."
    if [ -d "Burpsuite-Professional" ]; then
        log "Repository already exists. Updating..."
        cd Burpsuite-Professional || { log_error "Failed to enter repository directory"; exit 1; }
        git pull
    else
        git clone https://github.com/xiv3r/Burpsuite-Professional.git || { log_error "Failed to clone repository"; exit 1; }
        cd Burpsuite-Professional || { log_error "Failed to enter repository directory"; exit 1; }
    fi
    
    # Download Burpsuite Professional
    version="2025"
    jar_file="burpsuite_pro_v$version.jar"
    
    if [ -f "$jar_file" ]; then
        log "Burpsuite Professional JAR already exists."
        read -p "Download again? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$jar_file"
        else
            log "Skipping download."
        fi
    fi
    
    if [ ! -f "$jar_file" ]; then
        log "Downloading Burpsuite Professional Latest ($version)..."
        url="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar"
        
        # Use the appropriate download command
        if [[ "$download_cmd" == "axel"* ]]; then
            axel -a -n 10 "$url" -o "$jar_file" || { log_error "Failed to download Burpsuite JAR"; exit 1; }
        elif [[ "$download_cmd" == "wget"* ]]; then
            wget -O "$jar_file" "$url" || { log_error "Failed to download Burpsuite JAR"; exit 1; }
        elif [[ "$download_cmd" == "curl"* ]]; then
            curl -L -o "$jar_file" "$url" || { log_error "Failed to download Burpsuite JAR"; exit 1; }
        fi
    fi
    
    # Create the launcher script
    log "Creating launcher script..."
    cat > burpsuitepro << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:"$SCRIPT_DIR/loader.jar" \
     -noverify \
     -jar "$SCRIPT_DIR/burpsuite_pro_v2025.jar" "$@"
EOF
    chmod +x burpsuitepro
    
    # Create a desktop entry for GUI environments
    log "Creating desktop entry..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/burpsuitepro.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Burpsuite Professional
Comment=Web Security Testing Tool
Exec="$install_dir/Burpsuite-Professional/burpsuitepro"
Icon=burp
Terminal=false
Categories=Security;
EOF
    
    # Try to install the launcher system-wide if possible
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        log "Installing launcher to /usr/local/bin"
        sudo cp burpsuitepro /usr/local/bin/ || log_warning "Could not install to /usr/local/bin (permission denied)"
    elif [ -d "$HOME/.local/bin" ]; then
        log "Installing launcher to $HOME/.local/bin"
        cp burpsuitepro "$HOME/.local/bin/"
    else
        mkdir -p "$HOME/.local/bin"
        cp burpsuitepro "$HOME/.local/bin/"
        log_warning "Added launcher to $HOME/.local/bin. Make sure this directory is in your PATH."
        
        # Suggest adding to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log "You may need to add $HOME/.local/bin to your PATH:"
            log "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
        fi
    fi
    
    log_success "Installation completed successfully!"
    log "You can now start Burpsuite Professional by running:"
    log "  1. Start the key loader:   java -jar $install_dir/Burpsuite-Professional/loader.jar"
    log "  2. In another terminal:    burpsuitepro"
    log "  (Or use the desktop entry in your application menu if available)"
    
    # Ask user if they want to run Burpsuite now
    read -p "Launch Burpsuite Professional now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Starting Key loader..."
        (java -jar loader.jar) &
        loader_pid=$!
        sleep 2
        
        log "Executing Burpsuite Professional..."
        ./burpsuitepro
    fi
}

# Execute main function
main "$@"
