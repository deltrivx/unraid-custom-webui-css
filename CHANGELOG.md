# Changelog

## latest / 20260712-161553 - 2026-07-12

### Apps page compatibility

- Removed legacy Community Applications layout overrides that conflicted with the updated Apps interface in Unraid 7.3.2.
- Restored the Apps search bar, category sidebar, application grid, card sizing and content flow to the plugin's native layout.
- Removed custom fixed positioning, forced heights and independent scroll regions that caused header overlap, zero-height content areas and hidden application modules.
- Removed Apps-specific card backgrounds, hover colors, pagination, sorting and menu overrides so future Community Applications updates can provide their own presentation.
- Kept the global Cyberpunk theme, navigation, dashboard widgets and non-Apps page styling unchanged.
- Retained the code-editor compatibility fix from the previous release.

### Distribution

- Added immutable, timestamped theme archives under `versions/`.
- Added a `latest` version alias for the current recommended theme.
- Added an interactive version selector to the one-command installer.
- Added `--version`, `--list` and `--help` options for unattended installations.

## 20260711-231949 - 2026-07-11

- Archived the previous full-theme release using its final commit timestamp.
- This version retains the older custom Community Applications layout for users who need the legacy appearance.
