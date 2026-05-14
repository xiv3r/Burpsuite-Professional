#!/bin/bash

set -euo pipefail

show_help() {
    cat <<'EOF'
Burp Suite Professional helper scripts

Available commands:
  ./install_linux.sh   Interactive Linux menu used by this repository
  ./install.sh         Legacy Linux installer
  ./install_macos.sh   Legacy macOS installer
  ./install.ps1        Windows installer
  ./update.sh          Legacy updater
  ./help.sh            Show this help message

Security notes:
  - Prefer ./install_linux.sh over piping remote scripts into sudo bash.
  - Review any downloaded JAR before running it.
  - loader.jar is a Java executable/agent and should be treated as untrusted code unless you built and verified it yourself.
EOF
}

case "${1:-}" in
    ""|help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown argument: $1" >&2
        echo "Run ./help.sh for usage." >&2
        exit 1
        ;;
esac
