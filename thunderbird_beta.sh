#!/bin/bash
#
# Script para descargar Thunderbird Beta desde la web de Mozilla
#

locFilePath="$HOME/Descargas/thunderbird_beta.tar.xz"
urlLatest="https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=linux64&lang=es-ES"

wget -nv --show-progress -O "${locFilePath}" "${urlLatest}"

sudo tar -xJf "${locFilePath}" -C /opt
rm "${locFilePath}"

sudo ln -s /opt/thunderbird/thunderbird /usr/local/bin/thunderbird

sudo wget --no-clobber https://raw.githubusercontent.com/mozilla/sumo-kb/main/installing-thunderbird-linux/thunderbird.desktop -P /usr/share/applications/thunderbird-beta.desktop
