#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "install.sh is deprecated. Starting the maintained Linux menu instead."
exec "$SCRIPT_DIR/install_linux.sh"
