#!/bin/sh
set -eu

REPO_RAW="https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main"
PERSIST_DIR="/boot/config/plugins/custom.css"
RUNTIME_DIR="/usr/local/emhttp/plugins/custom.css"
DYNAMIX_CFG="/boot/config/plugins/dynamix/dynamix.cfg"
STATE_FILE="$PERSIST_DIR/unraid-custom-webui-css.state"
VERSION=""

download() {
  curl -4 -fsSL --connect-timeout 10 --max-time 180 --retry 2 "$@"
}

fetch_index() {
  download "$REPO_RAW/versions/index.json"
}

read_display_value() {
  key=$1
  sed -n "s/^${key}=\"\(.*\)\"$/\1/p" "$DYNAMIX_CFG" | head -n 1
}

set_display_value() {
  key=$1
  value=$2
  if grep -q "^${key}=" "$DYNAMIX_CFG"; then
    sed -i "s/^${key}=.*/${key}=\"${value}\"/" "$DYNAMIX_CFG"
  else
    sed -i "/^\[display\]$/a ${key}=\"${value}\"" "$DYNAMIX_CFG"
  fi
}

apply_display_settings() {
  if [ ! -f "$STATE_FILE" ]; then
    {
      printf 'theme=%s\n' "$(read_display_value theme)"
      printf 'header=%s\n' "$(read_display_value header)"
      printf 'headermetacolor=%s\n' "$(read_display_value headermetacolor)"
    } > "$STATE_FILE"
  fi
  set_display_value theme black
  set_display_value header ffffff
  set_display_value headermetacolor ffffff
}

restore_display_settings() {
  [ -f "$STATE_FILE" ] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      theme|header|headermetacolor) set_display_value "$key" "$value" ;;
    esac
  done < "$STATE_FILE"
  rm -f "$STATE_FILE"
}

install_version() {
  index=$(fetch_index)
  printf '%s' "$index" | jq -e --arg version "$VERSION" \
    '.versions[] | select(.id == $version)' >/dev/null || {
    echo "未知版本：$VERSION" >&2
    exit 64
  }

  base="$REPO_RAW/versions/$VERSION"
  tmp=$(mktemp -d /tmp/unraid-custom-webui-css.XXXXXX)
  trap 'rm -rf "$tmp"' EXIT INT TERM

  mkdir -p "$tmp/assets" "$PERSIST_DIR/assets" "$RUNTIME_DIR/assets"
  download -o "$tmp/style.css" "$base/style.css"
  download -o "$tmp/style-black.css" "$base/style-black.css"
  download -o "$tmp/assets/background.jpg" "$base/assets/background.jpg"

  install -m 0644 "$tmp/style.css" "$PERSIST_DIR/style.css"
  install -m 0644 "$tmp/style-black.css" "$PERSIST_DIR/style-black.css"
  install -m 0644 "$tmp/assets/background.jpg" "$PERSIST_DIR/assets/background.jpg"
  printf 'SERVICE="enabled"\n' > "$PERSIST_DIR/custom.css.cfg"

  install -m 0644 "$PERSIST_DIR/style.css" "$RUNTIME_DIR/style.css"
  install -m 0644 "$PERSIST_DIR/style-black.css" "$RUNTIME_DIR/style-black.css"
  install -m 0644 "$PERSIST_DIR/assets/background.jpg" "$RUNTIME_DIR/assets/background.jpg"
  apply_display_settings

  echo "主题 $VERSION 已安装。显示主题已设为黑色，页眉文字已设为白色。"
  echo "请强制刷新 Unraid WebGUI。"
}

select_and_install_version() {
  index=$(fetch_index)
  count=$(printf '%s' "$index" | jq '.versions | length')
  echo "可安装版本："
  i=0
  while [ "$i" -lt "$count" ]; do
    id=$(printf '%s' "$index" | jq -r ".versions[$i].id")
    label=$(printf '%s' "$index" | jq -r ".versions[$i].label")
    released=$(printf '%s' "$index" | jq -r ".versions[$i].released_at")
    channel=$(printf '%s' "$index" | jq -r ".versions[$i].channel")
    suffix=""
    [ "$channel" = "latest" ] && suffix=" [最新版]"
    printf '  %s) %s%s - %s（%s）\n' "$((i + 1))" "$id" "$suffix" "$label" "$released"
    i=$((i + 1))
  done
  printf '请选择版本 [1]：'
  read -r choice
  choice=${choice:-1}
  case "$choice" in *[!0-9]*|'') echo "无效选择" >&2; exit 64 ;; esac
  [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] || {
    echo "选择超出范围" >&2
    exit 64
  }
  VERSION=$(printf '%s' "$index" | jq -r ".versions[$((choice - 1))].id")
  install_version
}

uninstall_theme() {
  rm -f "$PERSIST_DIR/style.css" "$PERSIST_DIR/style-black.css" \
    "$PERSIST_DIR/assets/background.jpg"
  rm -f "$RUNTIME_DIR/style.css" "$RUNTIME_DIR/style-black.css" \
    "$RUNTIME_DIR/assets/background.jpg"
  printf 'SERVICE="disabled"\n' > "$PERSIST_DIR/custom.css.cfg"
  restore_display_settings
  rmdir "$PERSIST_DIR/assets" "$RUNTIME_DIR/assets" 2>/dev/null || true
  echo "主题已卸载，安装前的显示设置已恢复。请强制刷新 Unraid WebGUI。"
}

show_menu() {
  latest=$(fetch_index | jq -r '.latest_version')
  installed="未安装"
  [ -f "$PERSIST_DIR/style.css" ] && installed="已安装"
  cat <<EOF
Unraid Custom WebUI CSS 主题
当前状态：$installed

  1) 一键安装 / 升级最新版（$latest）
  2) 查看并安装全部版本
  3) 一键卸载主题
  4) 退出
EOF
  printf '请选择操作 [1]：'
  read -r action
  action=${action:-1}
  case "$action" in
    1) VERSION=$latest; install_version ;;
    2) select_and_install_version ;;
    3) uninstall_theme ;;
    4) exit 0 ;;
    *) echo "无效选择" >&2; exit 64 ;;
  esac
}

[ "$#" -eq 0 ] || {
  echo "此脚本仅使用交互菜单，不接受命令行参数。" >&2
  exit 64
}

[ "$(id -u)" -eq 0 ] || { echo "请使用 root 用户运行。" >&2; exit 77; }
command -v curl >/dev/null 2>&1 || { echo "缺少 curl。" >&2; exit 69; }
command -v jq >/dev/null 2>&1 || { echo "缺少 jq。" >&2; exit 69; }
[ -f "$DYNAMIX_CFG" ] || { echo "未找到 Unraid 显示设置文件。" >&2; exit 66; }
[ -t 0 ] || { echo "请在交互式 Unraid 终端中运行。" >&2; exit 64; }

show_menu
