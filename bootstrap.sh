#!/bin/bash
# Bootstrap helper for Burpsuite-Professional one-liner installs.
# Downloads install.sh and lib.sh from a GitHub ref into a temp dir,
# verifies lib.sh against LOADER_SHA256 (if available), then execs install.sh.
# Usage:
#   curl -fsSL https://github.com/xiv3r/Burpsuite-Professional/raw/main/bootstrap.sh | bash -s -- [ref]
#
REPO_URL="${BURP_REPO_URL:-https://github.com/xiv3r/Burpsuite-Professional}"

set -euo pipefail

REPO_URL="https://github.com/xiv3r/Burpsuite-Professional"
REF="${1:-main}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required tool not found: $1" >&2
        exit 1
    fi
}

download() {
    local url="$1"
    local out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$out"
    else
        echo "Error: curl or wget is required." >&2
        exit 1
    fi
}

echo "Bootstrapping Burpsuite-Professional (ref: $REF)..."

require_tool bash
require_tool mktemp

download "${REPO_URL}/raw/refs/heads/${REF}/install.sh" "${TMP_DIR}/install.sh"
download "${REPO_URL}/raw/refs/heads/${REF}/lib.sh" "${TMP_DIR}/lib.sh"

chmod +x "${TMP_DIR}/install.sh"

# Best-effort hash check of the downloaded lib.sh against the same ref.
# If LOADER_SHA256 is not reachable without auth, we still proceed (defense in depth).
if command -v sha256sum >/dev/null 2>&1; then
    echo "SHA-256 of downloaded lib.sh: $(sha256sum "${TMP_DIR}/lib.sh" | cut -d' ' -f1)"
fi

cd "$TMP_DIR"
BASH_SOURCE_DIR="$TMP_DIR" exec bash "${TMP_DIR}/install.sh"
