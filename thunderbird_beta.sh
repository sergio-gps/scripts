#!/bin/bash

# Script para descargar Thunderbird Beta desde la web de Mozilla

# Versión instalada
instalada=$(thunderbird --version 2>/dev/null | grep Thunderbird || echo "No detectada o no instalada")

# Versión actual/próxima
url="https://www.thunderbird.net/notes/beta/"
actual=$(curl -s -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$url" | grep -i "these notes apply to thunderbird version" | sed 's/<[^>]*>//g; s/^[ \t]*//; s/[ \t]*$//')

# URL bouncer (redirección a la última beta)
url_bouncer="https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=linux64&lang=es-ES"

# Resolvemos la URL final (seguimos redirecciones y mostramos solo la location final)
urlLatest=$(curl -I -L --fail "$url_bouncer" 2>/dev/null | grep -i "^location:" | tail -1 | awk '{print $2}' | tr -d '\r')

# Si no se resuelve bien, fallback
if [[ -z "$urlLatest" ]]; then
    echo "No se pudo resolver la URL final."
    exit 1
fi

echo "Versión instalada: $instalada"
echo "Versión actual/próxima: $actual"
echo "Versión lista para descargar: $urlLatest"

read -p "¿Continuar? Pulsa 'y' para sí, cualquier otra tecla para salir: " -n 1 -r
echo    # Salto de línea
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Saliendo del script..."
    exit 0
fi

locFilePath="$HOME/Descargas/thunderbird_beta.tar.xz"
icon="/usr/local/share/applications"

wget -nv --show-progress -O "${locFilePath}" "${urlLatest}"

sudo tar -xJf "${locFilePath}" -C /opt
rm "${locFilePath}"

sudo ln -s /opt/thunderbird/thunderbird /usr/local/bin/thunderbird

sudo wget --no-clobber https://raw.githubusercontent.com/mozilla/sumo-kb/main/installing-thunderbird-linux/thunderbird.desktop -P "$icon"

sudo mv "$icon"/thunderbird.desktop "$icon"/thunderbird-beta.desktop
