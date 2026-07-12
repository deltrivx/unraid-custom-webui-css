#!/bin/sh
set -eu

REPO_RAW="https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main"
PERSIST_DIR="/boot/config/plugins/custom.css"
RUNTIME_DIR="/usr/local/emhttp/plugins/custom.css"
VERSION=""

usage() {
  cat <<'EOF'
Usage: install.sh [--version VERSION] [--list] [--help]

Without arguments, an interactive version menu is shown when a terminal is available.
EOF
}

fetch_index() {
  curl -fsSL "$REPO_RAW/versions/index.json"
}

list_versions() {
  fetch_index | jq -r '.versions[] | "\(.id)\t\(.label)\t\(.released_at)"'
}

select_version() {
  index=$(fetch_index)
  count=$(printf '%s' "$index" | jq '.versions | length')
  printf 'Available theme versions:\n'
  i=0
  while [ "$i" -lt "$count" ]; do
    id=$(printf '%s' "$index" | jq -r ".versions[$i].id")
    label=$(printf '%s' "$index" | jq -r ".versions[$i].label")
    released=$(printf '%s' "$index" | jq -r ".versions[$i].released_at")
    printf '  %s) %s - %s (%s)\n' "$((i + 1))" "$id" "$label" "$released"
    i=$((i + 1))
  done
  printf 'Select version [1]: '
  read -r choice
  choice=${choice:-1}
  case "$choice" in
    *[!0-9]*|'') echo "Invalid selection" >&2; exit 64 ;;
  esac
  [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] || {
    echo "Selection out of range" >&2
    exit 64
  }
  VERSION=$(printf '%s' "$index" | jq -r ".versions[$((choice - 1))].id")
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) [ "$#" -ge 2 ] || { usage >&2; exit 64; }; VERSION=$2; shift 2 ;;
    --list) list_versions; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
done

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 69; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 69; }

if [ -z "$VERSION" ]; then
  if [ -t 0 ]; then
    select_version
  else
    VERSION=latest
  fi
fi

index=$(fetch_index)
printf '%s' "$index" | jq -e --arg version "$VERSION" \
  '.versions[] | select(.id == $version)' >/dev/null || {
  echo "Unknown version: $VERSION" >&2
  exit 64
}

base="$REPO_RAW/versions/$VERSION"
tmp=$(mktemp -d /tmp/unraid-custom-webui-css.XXXXXX)
trap 'rm -rf "$tmp"' EXIT INT TERM

mkdir -p "$tmp/assets" "$PERSIST_DIR/assets" "$RUNTIME_DIR/assets"
curl -fsSL -o "$tmp/style.css" "$base/style.css"
curl -fsSL -o "$tmp/style-black.css" "$base/style-black.css"
curl -fsSL -o "$tmp/assets/background.jpg" "$base/assets/background.jpg"

install -m 0644 "$tmp/style.css" "$PERSIST_DIR/style.css"
install -m 0644 "$tmp/style-black.css" "$PERSIST_DIR/style-black.css"
install -m 0644 "$tmp/assets/background.jpg" "$PERSIST_DIR/assets/background.jpg"
printf 'SERVICE="enabled"\n' > "$PERSIST_DIR/custom.css.cfg"

install -m 0644 "$PERSIST_DIR/style.css" "$RUNTIME_DIR/style.css"
install -m 0644 "$PERSIST_DIR/style-black.css" "$RUNTIME_DIR/style-black.css"
install -m 0644 "$PERSIST_DIR/assets/background.jpg" "$RUNTIME_DIR/assets/background.jpg"

echo "Custom WebUI CSS theme $VERSION installed. Refresh the Unraid WebGUI."
