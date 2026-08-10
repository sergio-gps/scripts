#!/bin/bash

steamapps_dir="$HOME/.local/share/Steam/steamapps"
compat_dir="$steamapps_dir/compatdata"

list() {
    for folder in "$compat_dir"/*; do
        [[ -d "$folder" ]] || continue

        appid=$(basename "$folder")
        acf_file="$steamapps_dir/appmanifest_${appid}.acf"

        # Obtener el nombre del juego desde su manifiesto
        if [[ -f "$acf_file" ]]; then
            name=$(grep -E '^\s*"name"' "$acf_file" | head -n 1 | cut -d '"' -f 4)
        else
            name="Desconocido / Non-Steam ($appid)"
        fi

        # Obtener la versión de Proton y la fecha de última modificación
        if [[ -f "$folder/version" ]]; then
            version=$(cat "$folder/version")
            mod_date=$(date -r "$folder/version" "+%Y-%m-%d %H:%M")
        else
            version="N/A"
            mod_date=$(date -r "$folder" "+%Y-%m-%d %H:%M")
        fi

        printf "%s\t%s\t%s\n" "$name" "$version" "$mod_date"
    done
}

list | sort -V -k 2 -r | column -t -s$'\t' -o ' | '
