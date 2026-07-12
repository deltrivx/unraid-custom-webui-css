# Changelog

## latest / 20260712-162652 - 2026-07-12

### Installer correction

- Kept the original one-command installer as the only documented upgrade entry point.
- The original command now opens an action menu where option 1 upgrades directly to `latest` and option 2 opens manual version selection.
- Removed the additional `--upgrade` command and its README example to avoid creating a second user workflow.
- Preserved `--version`, `--list` and `--help` as advanced compatibility and automation options.

## latest / 20260712-162005 - 2026-07-12

### Installer workflow

- Added a first-level interactive action menu for existing and new users.
- Added a one-step "Upgrade installed theme to latest" option as the default action.
- Kept manual version selection as a separate option for rollbacks and compatibility testing.
- Added an in-menu version list and a clean exit option.
- Kept the original one-command installer as the single user entry point; upgrades are selected from its interactive menu.
- Reused the same validated download and installation path for upgrades and fresh installs, so persistent and runtime theme files remain synchronized.

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
