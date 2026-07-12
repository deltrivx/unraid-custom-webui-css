# Unraid Custom WebUI CSS 主题

这是一个基于 **Custom WebUI CSS** 插件实现的 Unraid WebGUI 自定义主题，针对 Unraid 7.3.2 进行适配。主题包含赛博朋克背景、玻璃拟态模块、导航与模块圆角，以及新版 Community Applications 页面兼容样式。

## 效果预览

![仪表盘完整效果图](screenshots/dashboard-full.png)

## 安装前准备

1. 在 Unraid 的 Apps / Community Applications 中安装 **Custom WebUI CSS** 插件。
2. 确认 Unraid 可以访问 GitHub Raw 文件地址。
3. 使用 root 用户打开 Unraid 终端。

本主题使用 Custom WebUI CSS 插件，不是 Theme Engine。

## 一键安装、升级、回滚与卸载

所有操作只使用下面一个命令：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/deltrivx/unraid-custom-webui-css/main/scripts/install.sh)
```

脚本提供四个选项：

1. 一键安装 / 升级最新版：未安装时自动安装，已安装时自动覆盖升级。
2. 查看并安装全部版本：可选择最新版或任意历史版本进行安装、降级或回滚。
3. 一键卸载主题：删除主题文件、禁用 Custom WebUI CSS，并恢复安装前的显示设置。
4. 退出。

## 自动显示设置

安装任意版本时，脚本会自动执行 README 原先要求用户手动完成的显示设置：

```text
Dynamix color theme: Black
Header custom text color: #ffffff
Header custom secondary text color: #ffffff
Header custom background color: #000000
```

对应配置会写入 `/boot/config/plugins/dynamix/dynamix.cfg`。脚本仅在第一次安装时记录原值；重复升级不会覆盖备份。一键卸载时会恢复安装前的值。

## 主题文件

```text
/boot/config/plugins/custom.css/
├── style.css
├── style-black.css
└── assets/
    └── background.jpg
```

脚本同步维护持久目录与 WebGUI 运行目录，只覆盖本仓库管理的三个主题文件。

## 版本管理

- `versions/latest_version` 记录在 `versions/index.json` 中。
- `versions/v*` 保存可安装的语义化历史版本。
- GitHub 最新 Release 会标记为 Latest。
- 详细变化见 [CHANGELOG.md](CHANGELOG.md)。

## 常见问题

### 样式没有生效

检查 Custom WebUI CSS 是否启用：

```bash
cat /boot/config/plugins/custom.css/custom.css.cfg
```

正常应看到 `SERVICE="enabled"`。安装或升级后请强制刷新浏览器缓存：Windows/Linux 使用 `Ctrl + F5`，macOS 使用 `Command + Shift + R`。

### 背景图没有显示

```bash
ls -lh /boot/config/plugins/custom.css/assets/background.jpg
ls -lh /usr/local/emhttp/plugins/custom.css/assets/background.jpg
```

### 如何彻底清除主题

重新执行同一条一键命令，选择 `3) 一键卸载主题`。无需使用额外命令。

## 文件说明

- `style.css`：主题主样式。
- `style-black.css`：黑色主题兼容样式。
- `assets/background.jpg`：主题背景。
- `scripts/install.sh`：统一交互脚本。
- `versions/index.json`：版本清单。
- `CHANGELOG.md`：中文更新日志。
