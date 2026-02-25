#!/bin/bash

# =============================================================================
# help.sh - Display help for Burp Suite Professional
# 
# This is a simple contribution that adds a help command.
# It does not modify any existing files or functionality.
# Beginner-friendly script with clear comments.
# =============================================================================

# Colors for terminal output (green for success, red for errors, blue for info)
# These are just cosmetic - they make the help easier to read
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color - reset to normal terminal color

# Function to display help message
# This is called when user runs ./help.sh
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Burp Suite Professional Help${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Available commands:"
    echo ""
    echo -e "  ${GREEN}./install.sh${NC}     - Install Burp Suite Professional (Linux)"
    echo -e "  ${GREEN}./install_macos.sh${NC} - Install Burp Suite Professional (MacOS)"
    echo -e "  ${GREEN}./install.ps1${NC}    - Install Burp Suite Professional (Windows)"
    echo -e "  ${GREEN}./update.sh${NC}      - Update Burp Suite Professional"
    echo -e "  ${GREEN}./help.sh${NC}        - Show this help message"
    echo ""
    echo "Installation steps:"
    echo ""
    echo "  1. Run the installation script for your OS"
    echo "  2. Open Burp Suite Professional"
    echo "  3. Go to 'Help' > 'License'"
    echo "  4. Choose 'Manual activation'"
    echo "  5. Copy the request key from Burp"
    echo "  6. Paste it into the loader.jar"
    echo "  7. Copy the response key from loader"
    echo "  8. Paste it into Burp Suite Professional"
    echo ""
    echo -e "${RED}For more info, see README.md${NC}"
}

# Main script starts here
# Check if user wants help or gave no arguments
# $1 is the first argument passed to the script
if [ "$1" = "help" ] || [ -z "$1" ]; then
    # User asked for help or gave no arguments
    show_help
else
    # User gave an unknown argument
    echo -e "${RED}Unknown argument: $1${NC}"
    echo -e "${BLUE}Type './help.sh' to see available commands${NC}"
    exit 1  # Exit with error code 1
fi

# Exit successfully (error code 0)
exit 0
