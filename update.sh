#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "update.sh is deprecated. Use option 2 in the maintained Linux menu."
exec "$SCRIPT_DIR/install_linux.sh"
