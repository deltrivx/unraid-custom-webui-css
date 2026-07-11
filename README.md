# Unraid Custom WebUI CSS

This repository contains a custom Unraid WebGUI theme built for the **Custom WebUI CSS** plugin.

It is intended for Unraid `6.12.x` style WebGUI layouts and was exported from the current `192.168.31.2` system after the latest visual adjustments.

## Files

```text
/boot/config/plugins/custom.css/
├── style.css
├── style-black.css
└── assets/
    └── background.jpg
```

## Install

1. Install **Custom WebUI CSS** from the Unraid Apps / Community Applications store.
2. Download this repository's theme files into `/boot/config/plugins/custom.css/`.
3. Enable the plugin service.
4. Copy the files into the runtime plugin directory or refresh/restart the WebGUI.
5. Review the Display Settings notes in `docs/display-settings.md`.

### One-Line Install

Run this on the Unraid server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main/scripts/install.sh)
```

### Manual Install

```bash
mkdir -p /boot/config/plugins/custom.css/assets
mkdir -p /usr/local/emhttp/plugins/custom.css/assets

curl -fsSL -o /boot/config/plugins/custom.css/style.css \
  https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main/style.css
curl -fsSL -o /boot/config/plugins/custom.css/style-black.css \
  https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main/style-black.css
curl -fsSL -o /boot/config/plugins/custom.css/assets/background.jpg \
  https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main/assets/background.jpg

printf 'SERVICE="enabled"\n' > /boot/config/plugins/custom.css/custom.css.cfg

cp /boot/config/plugins/custom.css/style.css /usr/local/emhttp/plugins/custom.css/style.css
cp /boot/config/plugins/custom.css/style-black.css /usr/local/emhttp/plugins/custom.css/style-black.css
cp /boot/config/plugins/custom.css/assets/background.jpg /usr/local/emhttp/plugins/custom.css/assets/background.jpg
```

Refresh the Unraid WebGUI after installation.

## Update

Run the same one-line install command again. The script overwrites only the theme files managed by this repository.

## Rollback

Disable **Custom WebUI CSS** from the plugin settings, or remove these files:

```bash
rm -f /boot/config/plugins/custom.css/style.css
rm -f /boot/config/plugins/custom.css/style-black.css
rm -f /boot/config/plugins/custom.css/assets/background.jpg
rm -f /usr/local/emhttp/plugins/custom.css/style.css
rm -f /usr/local/emhttp/plugins/custom.css/style-black.css
rm -f /usr/local/emhttp/plugins/custom.css/assets/background.jpg
```

## Notes

- This theme uses Custom WebUI CSS, not Theme Engine.
- Keep the background image path as `assets/background.jpg`; the CSS references that location.
- If text contrast looks wrong after installation, check `docs/display-settings.md`.
