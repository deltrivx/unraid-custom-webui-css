#!/bin/sh
set -eu

REPO="https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main"
PERSIST_DIR="/boot/config/plugins/custom.css"
RUNTIME_DIR="/usr/local/emhttp/plugins/custom.css"

mkdir -p "$PERSIST_DIR/assets" "$RUNTIME_DIR/assets"

curl -fsSL -o "$PERSIST_DIR/style.css" "$REPO/style.css"
curl -fsSL -o "$PERSIST_DIR/style-black.css" "$REPO/style-black.css"
curl -fsSL -o "$PERSIST_DIR/assets/background.jpg" "$REPO/assets/background.jpg"

printf 'SERVICE="enabled"\n' > "$PERSIST_DIR/custom.css.cfg"

cp "$PERSIST_DIR/style.css" "$RUNTIME_DIR/style.css"
cp "$PERSIST_DIR/style-black.css" "$RUNTIME_DIR/style-black.css"
cp "$PERSIST_DIR/assets/background.jpg" "$RUNTIME_DIR/assets/background.jpg"

echo "Custom WebUI CSS theme installed. Refresh the Unraid WebGUI."
