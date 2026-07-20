#!/bin/sh
set -eu

REPO_RAW="https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main"
PERSIST_DIR="/boot/config/plugins/custom.css"
RUNTIME_DIR="/usr/local/emhttp/plugins/custom.css"
DYNAMIX_CFG="/boot/config/plugins/dynamix/dynamix.cfg"
STATE_FILE="$PERSIST_DIR/unraid-custom-webui-css.state"
OPTIONS_FILE="$PERSIST_DIR/unraid-custom-webui-css.options"
CA_PAGE="/usr/local/emhttp/plugins/community.applications/Apps.page"
LOADER_PAGE="$PERSIST_DIR/CustomCSS_Loader.page"
LOADER_RUNTIME="$RUNTIME_DIR/CustomCSS_Loader.page"
CA_MARK_START='<!-- unraid-custom-webui-css:apps-enhancement:start -->'
CA_MARK_END='<!-- unraid-custom-webui-css:apps-enhancement:end -->'
LOADER_MARK_START='<!-- unraid-custom-webui-css:apps-enhancement:start -->'
LOADER_MARK_END='<!-- unraid-custom-webui-css:apps-enhancement:end -->'
OLD_SIDEBAR_MARK_START='<!-- unraid-custom-webui-css:apps-mobile-sidebar-fix:start -->'
OLD_SIDEBAR_MARK_END='<!-- unraid-custom-webui-css:apps-mobile-sidebar-fix:end -->'
PARTICLES_START='/* unraid-custom-webui-css:particles:start */'
PARTICLES_END='/* unraid-custom-webui-css:particles:end */'
HUTAO_START='/* ===== unraid-custom-webui-css:hutao-mascot:start ===== */'
HUTAO_END='/* ===== unraid-custom-webui-css:hutao-mascot:end ===== */'

VERSION=""
INSTALL_PARTICLES="yes"
INSTALL_HUTAO="yes"
IS_LATEST="no"

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
  # Backup original display values once; never truncate an existing multi-key state file.
  if [ ! -f "$STATE_FILE" ]; then
    {
      printf 'theme=%s\n' "$(read_display_value theme)"
      printf 'header=%s\n' "$(read_display_value header)"
      printf 'headermetacolor=%s\n' "$(read_display_value headermetacolor)"
      printf 'background=%s\n' "$(read_display_value background)"
    } > "$STATE_FILE"
  else
    # Ensure the four display keys exist without wiping other notes/backups.
    for key in theme header headermetacolor background; do
      if ! grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
        printf '%s=%s\n' "$key" "$(read_display_value "$key")" >> "$STATE_FILE"
      fi
    done
  fi
  set_display_value theme black
  set_display_value header ffffff
  set_display_value headermetacolor ffffff
  set_display_value background 000000
}

restore_display_settings() {
  [ -f "$STATE_FILE" ] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      theme|header|headermetacolor|background) set_display_value "$key" "$value" ;;
    esac
  done < "$STATE_FILE"
  rm -f "$STATE_FILE"
}

ask_yn() {
  # $1 title multi-line help already printed; prompt ends with [Y/n]
  prompt=$1
  attempt=0
  while [ "$attempt" -lt 2 ]; do
    printf '%s' "$prompt"
    read -r ans || ans=""
    ans=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    case "$ans" in
      ''|y|yes) echo yes; return 0 ;;
      n|no) echo no; return 0 ;;
    esac
    echo "请输入 Y 或 N。"
    attempt=$((attempt + 1))
  done
  echo yes
}

prompt_optional_components() {
  INSTALL_PARTICLES="yes"
  INSTALL_HUTAO="yes"
  [ "$IS_LATEST" = "yes" ] || return 0

  cat <<EOF

可选组件（直接回车 = 安装）：

[1/2] 是否安装粒子特效？
  安装：背景更有层次，视觉更好看
  取消：页面更轻，流畅度提升更明显
EOF
  INSTALL_PARTICLES=$(ask_yn "  请选择 [Y/n]：")

  cat <<EOF

[2/2] 是否安装胡桃吉祥物？
  安装：右下角有个吉祥物陪着你
  取消：少加载一张大图，流畅度略有提升、界面更干净
EOF
  INSTALL_HUTAO=$(ask_yn "  请选择 [Y/n]：")
  echo
}

strip_css_block() {
  file=$1
  start=$2
  end=$3
  [ -f "$file" ] || return 0
  # Delete inclusive marker range; tolerate missing markers.
  if grep -Fq "$start" "$file" && grep -Fq "$end" "$file"; then
    # Use awk for portable block strip
    awk -v s="$start" -v e="$end" '
      $0 == s { skip=1; next }
      $0 == e { skip=0; next }
      !skip { print }
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  fi
}

remove_apps_enhancement() {
  if [ -f "$CA_PAGE" ]; then
    sed -i "\|$CA_MARK_START|,\|$CA_MARK_END|d" "$CA_PAGE" 2>/dev/null || true
    sed -i "\|$OLD_SIDEBAR_MARK_START|,\|$OLD_SIDEBAR_MARK_END|d" "$CA_PAGE" 2>/dev/null || true
  fi
  for page in "$LOADER_PAGE" "$LOADER_RUNTIME"; do
    if [ -f "$page" ]; then
      sed -i "\|$LOADER_MARK_START|,\|$LOADER_MARK_END|d" "$page" 2>/dev/null || true
      sed -i "\|$OLD_SIDEBAR_MARK_START|,\|$OLD_SIDEBAR_MARK_END|d" "$page" 2>/dev/null || true
    fi
  done
  rm -f \
    "$PERSIST_DIR/assets/apps-enhancement.js" \
    "$RUNTIME_DIR/assets/apps-enhancement.js" \
    "$PERSIST_DIR/assets/apps-mobile-sidebar-fix.js" \
    "$RUNTIME_DIR/assets/apps-mobile-sidebar-fix.js"
}

inject_loader_enhancement() {
  # Prefer CustomCSS_Loader.page (site-wide, works for route class sync).
  # Fall back to Apps.page if loader is missing.
  # remove_apps_enhancement already deleted old marks + JS; reinstall JS and inject once.
  install -m 0644 "$tmp/apps-enhancement.js" "$PERSIST_DIR/assets/apps-enhancement.js"
  install -m 0644 "$PERSIST_DIR/assets/apps-enhancement.js" "$RUNTIME_DIR/assets/apps-enhancement.js"

  snippet=$(cat <<EOF
$LOADER_MARK_START
<script src="/plugins/custom.css/assets/apps-enhancement.js?v=$VERSION"></script>
$LOADER_MARK_END
EOF
)

  if [ -f "$LOADER_PAGE" ]; then
    printf '\n%s\n' "$snippet" >> "$LOADER_PAGE"
    if [ -f "$LOADER_RUNTIME" ]; then
      # Keep runtime loader in sync (marks already stripped by remove_apps_enhancement).
      printf '\n%s\n' "$snippet" >> "$LOADER_RUNTIME"
    else
      # First install path: mirror persist loader into runtime if runtime dir exists.
      mkdir -p "$RUNTIME_DIR"
      cp -a "$LOADER_PAGE" "$LOADER_RUNTIME" 2>/dev/null || true
    fi
  elif [ -f "$CA_PAGE" ]; then
    printf '\n%s\n' "$snippet" >> "$CA_PAGE"
  else
    echo "未检测到 CustomCSS_Loader / Community Applications，已跳过应用页增强注入。"
  fi
}

remove_hutao_assets() {
  rm -f "$PERSIST_DIR/assets/hutao.gif" "$RUNTIME_DIR/assets/hutao.gif"
}

write_options() {
  {
    printf 'version=%s\n' "$VERSION"
    printf 'particles=%s\n' "$INSTALL_PARTICLES"
    printf 'hutao=%s\n' "$INSTALL_HUTAO"
    printf 'updated_at=%s\n' "$(date +%Y%m%d-%H%M%S)"
    printf 'source=deltrivx/unraid-custom-webui-css\n'
  } > "$OPTIONS_FILE"
}

install_version() {
  index=$(fetch_index)
  printf '%s' "$index" | jq -e --arg version "$VERSION" \
    '.versions[] | select(.id == $version)' >/dev/null || {
    echo "未知版本：$VERSION" >&2
    exit 64
  }

  latest=$(printf '%s' "$index" | jq -r '.latest_version')
  if [ "$VERSION" = "$latest" ]; then
    IS_LATEST="yes"
  else
    IS_LATEST="no"
    INSTALL_PARTICLES="yes"
    INSTALL_HUTAO="no"
  fi

  prompt_optional_components

  # Historical packages do not ship hutao; force off.
  if [ "$IS_LATEST" != "yes" ]; then
    INSTALL_HUTAO="no"
  fi

  base="$REPO_RAW/versions/$VERSION"
  tmp=$(mktemp -d /tmp/unraid-custom-webui-css.XXXXXX)
  trap 'rm -rf "$tmp"' EXIT INT TERM

  mkdir -p "$tmp/assets" "$PERSIST_DIR/assets" "$RUNTIME_DIR/assets"
  download -o "$tmp/style.css" "$base/style.css"
  download -o "$tmp/style-black.css" "$base/style-black.css"
  download -o "$tmp/assets/background.jpg" "$base/assets/background.jpg"

  apps_enhancement=$(printf '%s' "$index" | jq -r --arg version "$VERSION" \
    '.versions[] | select(.id == $version) | .apps_enhancement // false')
  if [ "$apps_enhancement" = "true" ]; then
    download -o "$tmp/apps-enhancement.js" "$base/apps-enhancement.js"
  fi

  if [ "$INSTALL_HUTAO" = "yes" ]; then
    download -o "$tmp/assets/hutao.gif" "$base/assets/hutao.gif"
  fi

  if [ "$INSTALL_PARTICLES" != "yes" ]; then
    strip_css_block "$tmp/style.css" "$PARTICLES_START" "$PARTICLES_END"
  fi
  if [ "$INSTALL_HUTAO" != "yes" ]; then
    strip_css_block "$tmp/style.css" "$HUTAO_START" "$HUTAO_END"
  fi

  install -m 0644 "$tmp/style.css" "$PERSIST_DIR/style.css"
  install -m 0644 "$tmp/style-black.css" "$PERSIST_DIR/style-black.css"
  install -m 0644 "$tmp/assets/background.jpg" "$PERSIST_DIR/assets/background.jpg"
  printf 'SERVICE="enabled"\n' > "$PERSIST_DIR/custom.css.cfg"

  install -m 0644 "$PERSIST_DIR/style.css" "$RUNTIME_DIR/style.css"
  install -m 0644 "$PERSIST_DIR/style-black.css" "$RUNTIME_DIR/style-black.css"
  install -m 0644 "$PERSIST_DIR/assets/background.jpg" "$RUNTIME_DIR/assets/background.jpg"

  if [ "$INSTALL_HUTAO" = "yes" ]; then
    install -m 0644 "$tmp/assets/hutao.gif" "$PERSIST_DIR/assets/hutao.gif"
    install -m 0644 "$PERSIST_DIR/assets/hutao.gif" "$RUNTIME_DIR/assets/hutao.gif"
  else
    remove_hutao_assets
  fi

  remove_apps_enhancement
  if [ "$apps_enhancement" = "true" ]; then
    inject_loader_enhancement
  fi
  apply_display_settings
  write_options
  # Soft-update state metadata keys without clobbering display backups / notes.
  {
    grep -vE '^(version|particles|hutao|apps_enhancement|updated_at|source)=' "$STATE_FILE" 2>/dev/null || true
    printf 'version=%s\n' "$VERSION"
    printf 'particles=%s\n' "$INSTALL_PARTICLES"
    printf 'hutao=%s\n' "$INSTALL_HUTAO"
    printf 'apps_enhancement=%s\n' "$apps_enhancement"
    printf 'updated_at=%s\n' "$(date +%Y%m%d-%H%M%S)"
    printf 'source=deltrivx/unraid-custom-webui-css\n'
  } > "$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"

  particles_label="已跳过"
  hutao_label="已跳过"
  [ "$INSTALL_PARTICLES" = "yes" ] && particles_label="已启用"
  [ "$INSTALL_HUTAO" = "yes" ] && hutao_label="已启用"

  echo "已安装：主题 $VERSION"
  echo "  粒子特效：$particles_label"
  echo "  胡桃吉祥物：$hutao_label"
  echo "显示主题和标题背景已设为黑色，页眉文字已设为白色。"
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
  remove_hutao_assets
  remove_apps_enhancement
  rm -f "$OPTIONS_FILE"
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
