#!/bin/bash
# Library of shared helpers for Burpsuite-Professional bash installers.
# Sourced by install.sh, update.sh and install_macos.sh.
# Requires bash. Compatible with bash 3.2 (macOS default) and newer.
set -uo pipefail

# Print a normalized, trimmed, lowercase string read from a file.
# Usage: read_value <file>
read_value() {
    if [[ $# -ne 1 ]]; then
        echo "Error: read_value requires exactly one argument." >&2
        return 1
    fi
    if [[ ! -f "$1" ]]; then
        echo "Error: file not found: $1" >&2
        return 1
    fi
    local raw
    raw=$(<"$1") || return 1
    printf '%s' "$raw" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

# Read the Burp Suite version from VERSION.
# Sets $bp_version or returns 1 on failure.
read_version() {
    bp_version=$(read_value "VERSION") || return 1
    if [[ -z "$bp_version" ]]; then
        echo "Error: VERSION file is empty." >&2
        return 1
    fi
}

# Compute SHA-256 of a file using the best available tool.
# Prints lowercase hex. Supports sha256sum (Linux) and shasum -a 256 (macOS).
hash_sha256() {
    if [[ $# -ne 1 ]]; then
        echo "Error: hash_sha256 requires exactly one argument." >&2
        return 1
    fi
    if [[ ! -f "$1" ]]; then
        echo "Error: file not found: $1" >&2
        return 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}' | tr '[:upper:]' '[:lower:]'
    else
        echo "Error: no SHA-256 tool found (sha256sum or shasum)." >&2
        return 1
    fi
}

# Verify a file against an expected lowercase SHA-256.
# Returns 0 if match, 1 otherwise. Prints success/error messages.
verify_sha256() {
    if [[ $# -ne 2 ]]; then
        echo "Error: verify_sha256 requires file and expected hash." >&2
        return 1
    fi
    local file="$1"
    local expected="$2"
    local actual

    if ! actual=$(hash_sha256 "$file"); then
        return 1
    fi

    if [[ "$actual" != "$expected" ]]; then
        echo "Error: SHA-256 mismatch for ${file}: expected ${expected}, got ${actual}." >&2
        return 1
    fi
    echo "SHA-256 verified for ${file}"
}

# Download a URL to a file and verify its SHA-256.
# Uses wget if available, otherwise curl.
# Returns 0 on success, 1 on failure.
download_with_hash() {
    if [[ $# -ne 3 ]]; then
        echo "Error: download_with_hash requires url, out_file and expected hash." >&2
        return 1
    fi
    local url="$1"
    local out_file="$2"
    local expected="$3"

    echo "Downloading ${out_file}..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "$out_file" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$out_file"
    else
        echo "Error: no download tool found (wget or curl)." >&2
        return 1
    fi

    if ! verify_sha256 "$out_file" "$expected"; then
        rm -f "$out_file"
        return 1
    fi
}

# Ensure a command exists. Prints an error and returns 1 if missing.
require_command() {
    if [[ $# -ne 1 ]]; then
        echo "Error: require_command requires a command name." >&2
        return 1
    fi
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command not found: $1" >&2
        return 1
    fi
}

# Compute SHA-256 of the bundled loader.jar and verify it against LOADER_SHA256.
# Returns 0 on success, 1 otherwise.
verify_loader() {
    local expected
    if ! expected=$(read_value "LOADER_SHA256"); then
        return 1
    fi
    if [[ -z "$expected" ]]; then
        echo "Error: LOADER_SHA256 is empty." >&2
        return 1
    fi
    verify_sha256 "loader.jar" "$expected"
}
