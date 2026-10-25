# 草稿图片放大 · 点一下看大图

HanaAgent 聊天输入框里粘贴或附加图片后，草稿区只有一个小小的缩略图，点它没反应；发出去之后消息里的图倒是能点开。这个 skill 补上草稿阶段的那一截。

## 装上之后能干什么

- **单击草稿缩略图 → 全屏看大图**
- 草稿里有多张图 → 左右箭头切换（键盘 ← → 也行）
- **滚轮缩放**，放大后可以拖动
- 双击在 1× / 2× 之间切，`0` 复位，`Esc` 或点背景关闭

## 安装

装成 skill 之后，Agent 会按 `SKILL.md` 里的流程自动完成安装；也可以自己手动跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1
```

Windows PowerShell 5.1 和 PowerShell 7 都能跑。装完**完全退出 Hana 再启动**（托盘图标也要退干净）。

想先看当前状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Check
```

想撤掉或还原：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Uninstall   # 撤掉
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Restore     # 出问题时还原
```

## 它改了什么

只有两个文件，都在 Hana 自己的 renderer 目录里（`~/.hanako/artifacts/renderer/<版本>/`）：

- `modules/draft-image-zoom.js` —— 新增，功能脚本
- `index.html` —— 在 `</body>` 前插一行 `<script src="modules/draft-image-zoom.js" data-hdiz="1"></script>`

不碰打包后的 chunk，不改 Program Files 里的安装目录，不联网，不读也不写任何用户数据。首次修改前脚本自动把 `index.html` 备份成 `index.html.hdiz.bak`，卸载和还原都靠这份备份，卸载后 `index.html` 与安装前字节一致。

## 一个要知道的限制

**Hana 每更新一次，这个功能就会消失一次，需要重跑一次安装脚本。**

官方更新会把 renderer 解包成新的版本目录，`index.html` 被换成新的，注入的那行随之不见。这不是脚本坏了，是本地补丁的固有代价。脚本每次安装都会自动指向最新的版本目录，所以重跑一条命令就能恢复。

## 已知边界

- 只作用于主窗口。快速对话、手机版、平板版走的是别的入口页，不覆盖。
- 只处理图片和 svg 缩略图，音频和普通文件不管。
- 只取缩略图 `img` 元素上的 `src`；上游如果改成背景图，这里要跟着改。
- 这是本地补丁，不是官方功能。

## 权限与外部服务

无。脚本不联网，不访问任何外部服务，不读取或写入用户数据，只在用户自己的 Hana 安装目录里改两个文件。
