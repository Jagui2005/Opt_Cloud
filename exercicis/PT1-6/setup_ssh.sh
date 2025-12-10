#!/bin/bash

SSH_DIR=~/.ssh
CONFIG_FILE="ssh_config_per_connect.txt"

echo "Iniciando configuración local de SSH..."

mkdir -p "$SSH_DIR"

echo "Moviendo y protegiendo las claves..."
find . -maxdepth 1 -name "*.pem" -print0 | while IFS= read -r -d $'\0' file; do
    echo "  -> Moviendo $file a $SSH_DIR/"
    mv "$file" "$SSH_DIR/"
    chmod 400 "$SSH_DIR/$(basename $file)"
done

if [ -f "$CONFIG_FILE" ]; then
    echo "Añadiendo la configuración de ProxyJump a $SSH_DIR/config..."
    
    START_MARKER="# START TERRAFORM CLOUD RA1 CONFIG"
    END_MARKER="# END TERRAFORM CLOUD RA1 CONFIG"

    if grep -qF "$START_MARKER" "$SSH_DIR/config" 2>/dev/null; then
        echo "  -> Eliminando configuración anterior..."
        awk "/$START_MARKER/,/$END_MARKER/ {next} {print}" "$SSH_DIR/config" > "$SSH_DIR/config.tmp" && mv "$SSH_DIR/config.tmp" "$SSH_DIR/config"
    fi

    cat "$CONFIG_FILE" >> "$SSH_DIR/config"
    echo "Configuración completada."
    
    rm "$CONFIG_FILE"
else
    echo "ERROR: No se ha encontrado el archivo $CONFIG_FILE. Asegúrate de ejecutar 'terraform apply' antes."
fi

echo "¡Hecho! Ya puedes conectarte con 'ssh bastion' o 'ssh private-1'."