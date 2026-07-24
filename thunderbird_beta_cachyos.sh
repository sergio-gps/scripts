#!/usr/bin/env bash
set -euo pipefail

# Script para descargar e instalar/actualizar Thunderbird Beta en CachyOS (Arch-based)

# ---------------------------
# Configuración
# ---------------------------
LANG_CODE="es-ES"
NOTES_URL="https://www.thunderbird.net/notes/beta/"
BOUNCER_URL="https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=linux64&lang=${LANG_CODE}"

INSTALL_DIR="/opt/thunderbird-beta"
BIN_LINK="/usr/local/bin/thunderbird-beta"
DESKTOP_FILE_SYSTEM="/usr/local/share/applications/thunderbird-beta.desktop"

# Descargas en ruta XDG si existe; fallback a ~/Descargas
DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Descargas}"
mkdir -p "$DOWNLOAD_DIR"
TARBALL_PATH="${DOWNLOAD_DIR}/thunderbird-beta.tar.xz"

# ---------------------------
# Comprobación de dependencias
# ---------------------------
# Paquetes (repos oficiales): curl, wget, tar, grep, awk, sed
REQUIRED_CMDS=(curl wget tar grep awk sed)
MISSING=()

for cmd in "${REQUIRED_CMDS[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done

if (( ${#MISSING[@]} > 0 )); then
  echo "Faltan dependencias: ${MISSING[*]}"
  echo "Instálalas con:"
  echo "  sudo pacman -S --needed ${MISSING[*]}"
  exit 1
fi

# ---------------------------
# Información de versión instalada
# ---------------------------
if command -v thunderbird-beta >/dev/null 2>&1; then
  INSTALLED_VERSION="$(thunderbird-beta --version 2>/dev/null || echo "No detectada")"
elif command -v thunderbird >/dev/null 2>&1; then
  INSTALLED_VERSION="$(thunderbird --version 2>/dev/null || echo "No detectada")"
else
  INSTALLED_VERSION="No detectada o no instalada"
fi

# ---------------------------
# Versión actual/próxima (release notes beta)
# ---------------------------
CURRENT_BETA_VERSION="$(
  curl -fsSL -A "Mozilla/5.0" "$NOTES_URL" \
    | grep -i "these notes apply to thunderbird version" \
    | sed -E 's/.*version[[:space:]]+([0-9.]+).*/\1/I' \
    | head -n1
)"

if [[ -z "${CURRENT_BETA_VERSION:-}" ]]; then
  CURRENT_BETA_VERSION="No se pudo detectar automáticamente"
fi

# ---------------------------
# Resolver URL final de descarga
# ---------------------------
LATEST_URL="$(
  curl -fsSLI -o /dev/null -w '%{url_effective}' "$BOUNCER_URL" || true
)"

if [[ -z "${LATEST_URL:-}" ]]; then
  echo "No se pudo resolver la URL final de descarga."
  exit 1
fi

echo "Versión instalada: ${INSTALLED_VERSION}"
echo "Versión actual/próxima: ${CURRENT_BETA_VERSION}"
echo "Versión lista para descargar: ${LATEST_URL}"
echo

read -r -n 1 -p "¿Continuar? Pulsa 'y' para sí, cualquier otra tecla para salir: " REPLY
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  echo "Saliendo del script..."
  exit 0
fi

# ---------------------------
# Descarga
# ---------------------------
echo "Descargando Thunderbird Beta..."
wget -nv --show-progress -O "$TARBALL_PATH" "$LATEST_URL"

# ---------------------------
# Instalación en /opt (Arch-style para binarios externos)
# ---------------------------
echo "Instalando en ${INSTALL_DIR}..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

# El tarball contiene normalmente carpeta "thunderbird/"
sudo tar -xJf "$TARBALL_PATH" -C /opt
rm -f "$TARBALL_PATH"

# Si extrajo /opt/thunderbird, la movemos a /opt/thunderbird-beta
if [[ -d /opt/thunderbird ]]; then
  sudo rm -rf "$INSTALL_DIR"
  sudo mv /opt/thunderbird "$INSTALL_DIR"
fi

# Enlace binario específico beta (evita pisar thunderbird estable del sistema)
echo "Creando enlace binario: ${BIN_LINK}"
sudo ln -sfn "${INSTALL_DIR}/thunderbird" "$BIN_LINK"

# .desktop para integración del lanzador
echo "Creando lanzador desktop..."
sudo mkdir -p /usr/local/share/applications

if [[ ! -e "$DESKTOP_FILE_SYSTEM" ]]; then
  sudo tee "$DESKTOP_FILE_SYSTEM" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Name=Thunderbird Beta
GenericName=Mail Client
Comment=Read and write email
Exec=${BIN_LINK} %u
Terminal=false
Type=Application
Icon=${INSTALL_DIR}/chrome/icons/default/default128.png
Categories=Network;Email;
MimeType=x-scheme-handler/mailto;
StartupNotify=true
EOF
else
  echo "El archivo desktop ya existe, no se modifica: $DESKTOP_FILE_SYSTEM"
fi

# Cache de escritorio (si está disponible)
if command -v update-desktop-database >/dev/null 2>&1; then
  sudo update-desktop-database /usr/local/share/applications || true
fi

echo
echo "Instalación/actualización completada."
echo "Puedes ejecutar Thunderbird Beta con: thunderbird-beta"
