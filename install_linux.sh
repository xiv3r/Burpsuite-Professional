#!/usr/bin/env bash

# Burp Suite Desktop - Kali/Debian installer
# Instala el JAR oficial de PortSwigger.
#
# NO ejecutar con:
#   sudo bash script.sh
#
# Ejecutar como usuario normal:
#   chmod +x install_burp.sh
#   ./install_burp.sh
#
# El script utiliza sudo únicamente cuando lo necesita.

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BURP_URL="https://portswigger.net/burp/releases/download?product=pro&type=Jar"

INSTALL_DIR="${HOME}/.local/share/burpsuite"
BURP_JAR="${INSTALL_DIR}/burpsuite.jar"

BIN_DIR="${HOME}/.local/bin"
LAUNCHER="${BIN_DIR}/burpsuitepro"

DESKTOP_DIR="${HOME}/.local/share/applications"
DESKTOP_FILE="${DESKTOP_DIR}/burpsuite-professional.desktop"

MIN_JAVA=21

# ---------------------------------------------------------------------------
# Colors / logging
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
    BLUE=$'\033[1;34m'
    GREEN=$'\033[1;32m'
    YELLOW=$'\033[1;33m'
    RED=$'\033[1;31m'
    RESET=$'\033[0m'
else
    BLUE=""
    GREEN=""
    YELLOW=""
    RED=""
    RESET=""
fi

log() {
    printf '%s[*]%s %s\n' "$BLUE" "$RESET" "$*"
}

ok() {
    printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"
}

warn() {
    printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2
}

die() {
    printf '%s[x]%s %s\n' "$RED" "$RESET" "$*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Error handler
# ---------------------------------------------------------------------------

trap 'printf "%s[x]%s Error en linea %s: %s\n" \
    "$RED" "$RESET" "$LINENO" "$BASH_COMMAND" >&2' ERR

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------

if (( EUID == 0 )); then
    cat >&2 <<'EOF'
No ejecutes este instalador como root ni mediante:

    wget ... | sudo bash

Ejecutalo como tu usuario normal. El propio script utilizara sudo
solo para instalar paquetes si es necesario.
EOF
    exit 1
fi

# ---------------------------------------------------------------------------
# Interactive input
#
# /dev/tty is used deliberately so stdin may be a pipe without breaking
# the interactive menu.
# ---------------------------------------------------------------------------

read_tty() {
    local __var="$1"
    local __prompt="$2"
    local __value=""

    [[ -r /dev/tty ]] || die "No existe un terminal interactivo (/dev/tty)."

    printf '%s' "$__prompt" > /dev/tty
    IFS= read -r __value < /dev/tty || true

    printf -v "$__var" '%s' "$__value"
}

pause() {
    local dummy=""
    printf '\n'
    read_tty dummy "Pulsa Enter para continuar..."
}

# ---------------------------------------------------------------------------
# Java
# ---------------------------------------------------------------------------

java_major_version() {
    local version=""

    command -v java >/dev/null 2>&1 || {
        printf '0\n'
        return
    }

    version="$(
        java -version 2>&1 |
        awk -F '"' '/version/ { print $2; exit }'
    )"

    if [[ "$version" =~ ^1\.([0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    elif [[ "$version" =~ ^([0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    else
        printf '0\n'
    fi
}

check_dependencies() {
    local need=()
    local java_major

    command -v curl >/dev/null 2>&1 || need+=(curl)
    command -v ca-certificates >/dev/null 2>&1 || true

    java_major="$(java_major_version)"

    if (( java_major < MIN_JAVA )); then
        need+=(openjdk-21-jre)
    fi

    if ((${#need[@]} == 0)); then
        ok "Dependencias disponibles."
        ok "Java $(java_major_version) detectado."
        return 0
    fi

    command -v apt-get >/dev/null 2>&1 ||
        die "No encuentro apt-get. Instala manualmente curl y Java ${MIN_JAVA}+."

    log "Instalando dependencias: ${need[*]}"

    sudo apt-get update

    sudo apt-get install -y \
        --no-install-recommends \
        ca-certificates \
        "${need[@]}"

    java_major="$(java_major_version)"

    (( java_major >= MIN_JAVA )) ||
        die "Burp necesita Java ${MIN_JAVA} o superior."

    ok "Java ${java_major} disponible."
}

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------

create_directories() {
    install -d -m 0755 "$INSTALL_DIR"
    install -d -m 0755 "$BIN_DIR"
    install -d -m 0755 "$DESKTOP_DIR"
}

# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------

download_burp() {
    local tmp

    create_directories

    tmp="$(mktemp "${INSTALL_DIR}/burpsuite.jar.XXXXXX")"

    cleanup_download() {
        rm -f "$tmp"
    }

    trap cleanup_download RETURN

    log "Descargando Burp Suite desde PortSwigger..."

    curl \
        --fail \
        --location \
        --show-error \
        --retry 3 \
        --retry-delay 2 \
        --connect-timeout 20 \
        --output "$tmp" \
        "$BURP_URL"

    [[ -s "$tmp" ]] ||
        die "El archivo descargado esta vacio."

    # ZIP/JAR files normally start with PK.
    if ! head -c 2 "$tmp" | grep -q 'PK'; then
        warn "El archivo descargado no parece ser un JAR valido."
        warn "Primeras lineas de la respuesta:"
        head -n 5 "$tmp" >&2 || true
        return 1
    fi

    chmod 0644 "$tmp"
    mv -f "$tmp" "$BURP_JAR"

    trap - RETURN

    ok "Burp instalado en:"
    printf '    %s\n' "$BURP_JAR"
}

# ---------------------------------------------------------------------------
# Command launcher
# ---------------------------------------------------------------------------

install_launcher() {
    create_directories

    cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
set -e

BURP_JAR="${BURP_JAR}"

if [[ ! -f "\$BURP_JAR" ]]; then
    echo "Burp Suite no esta instalado: \$BURP_JAR" >&2
    exit 1
fi

exec java -jar "\$BURP_JAR" "\$@"
EOF

    chmod 0755 "$LAUNCHER"

    ok "Comando instalado:"
    printf '    %s\n' "$LAUNCHER"

    case ":${PATH}:" in
        *":${BIN_DIR}:"*)
            ;;
        *)
            warn "${BIN_DIR} no esta actualmente en PATH."
            printf '\nAnade esto a ~/.zshrc si usas zsh:\n\n'
            printf '    export PATH="$HOME/.local/bin:$PATH"\n\n'
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Desktop entry
# ---------------------------------------------------------------------------

install_desktop_launcher() {
    create_directories

    [[ -x "$LAUNCHER" ]] || install_launcher

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Burp Suite
Comment=Web Security Testing Tool
Exec=${LAUNCHER}
Icon=applications-development
Terminal=false
Categories=Development;Security;
StartupNotify=true
StartupWMClass=burpsuite
EOF

    chmod 0644 "$DESKTOP_FILE"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
    fi

    ok "Launcher de escritorio creado:"
    printf '    %s\n' "$DESKTOP_FILE"
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install_burp() {
    check_dependencies

    if [[ -f "$BURP_JAR" ]]; then
        local answer=""
        read_tty answer \
            "Burp ya esta instalado. Quieres descargarlo de nuevo? [y/N] "

        case "${answer:-n}" in
            y|Y|yes|YES|s|S|si|SI)
                download_burp
                ;;
            *)
                log "Manteniendo JAR existente."
                ;;
        esac
    else
        download_burp
    fi

    install_launcher

    ok "Instalacion completada."

    printf '\nEjecuta:\n\n'
    printf '    burpsuitepro\n\n'
    printf 'En Burp Professional introduce tu licencia oficial cuando se solicite.\n'
}

# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

update_burp() {
    check_dependencies

    log "Actualizando Burp Suite..."
    download_burp

    [[ -x "$LAUNCHER" ]] || install_launcher

    ok "Actualizacion completada."
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

run_burp() {
    [[ -f "$BURP_JAR" ]] ||
        die "Burp no esta instalado. Usa primero la opcion de instalacion."

    local java_major
    java_major="$(java_major_version)"

    (( java_major >= MIN_JAVA )) ||
        die "Burp necesita Java ${MIN_JAVA}+; detectado: ${java_major}"

    log "Iniciando Burp Suite..."

    java -jar "$BURP_JAR"
}

# ---------------------------------------------------------------------------
# Remove
# ---------------------------------------------------------------------------

remove_burp() {
    local answer=""

    read_tty answer \
        "Eliminar Burp, launcher y acceso del menu? [y/N] "

    case "${answer:-n}" in
        y|Y|yes|YES|s|S|si|SI)
            rm -rf "$INSTALL_DIR"
            rm -f "$LAUNCHER"
            rm -f "$DESKTOP_FILE"

            if command -v update-desktop-database >/dev/null 2>&1; then
                update-desktop-database "$DESKTOP_DIR" \
                    >/dev/null 2>&1 || true
            fi

            ok "Burp eliminado."
            ;;
        *)
            log "Operacion cancelada."
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

diagnostics() {
    printf '\n'
    printf 'Usuario:        %s\n' "$USER"
    printf 'HOME:           %s\n' "$HOME"
    printf 'Install dir:    %s\n' "$INSTALL_DIR"
    printf 'JAR:            %s\n' "$BURP_JAR"
    printf 'Launcher:       %s\n' "$LAUNCHER"
    printf 'Desktop file:   %s\n' "$DESKTOP_FILE"
    printf 'Java:           '

    if command -v java >/dev/null 2>&1; then
        java -version 2>&1 | head -n 1
    else
        printf 'no instalado\n'
    fi

    printf '\n'

    if [[ -f "$BURP_JAR" ]]; then
        printf 'Burp JAR:       instalado\n'
        if command -v sha256sum >/dev/null 2>&1; then
            printf 'SHA256:         '
            sha256sum "$BURP_JAR" | awk '{print $1}'
        fi
    else
        printf 'Burp JAR:       no instalado\n'
    fi

    printf '\n'
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

menu() {
    local opt=""

    while true; do
        clear 2>/dev/null || true

        cat <<'EOF'

Burp Suite - Installer
----------------------------------------
1) Instalar Burp Suite
2) Actualizar Burp Suite
3) Ejecutar Burp Suite
4) Instalar comando burpsuitepro
5) Crear launcher de escritorio
6) Diagnostico
7) Desinstalar
8) Salir
----------------------------------------
EOF

        read_tty opt "Selecciona una opcion [1-8]: "

        case "$opt" in
            1)
                install_burp
                pause
                ;;
            2)
                update_burp
                pause
                ;;
            3)
                run_burp
                pause
                ;;
            4)
                install_launcher
                pause
                ;;
            5)
                install_desktop_launcher
                pause
                ;;
            6)
                diagnostics
                pause
                ;;
            7)
                remove_burp
                pause
                ;;
            8)
                exit 0
                ;;
            *)
                warn "Opcion invalida."
                pause
                ;;
        esac
    done
}

menu
