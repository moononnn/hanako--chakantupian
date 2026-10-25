# hana-draft-image-zoom

给 HanaAgent 聊天输入框里粘贴/附加的图片缩略图加一个**点击看大图**。

输入框草稿区只给一个小缩略图，点它没反应；发出去之后消息里的图倒是能点开。这个 skill 补上了草稿阶段的那一截。

<!-- 截图占位：贴一张「点击缩略图后全屏预览」的截图到这里 -->

## 效果

- 单击草稿缩略图 → 全屏预览
- 草稿里有多张图 → 左右箭头切换（键盘 ← → 也行）
- 滚轮缩放，放大后可拖动
- 双击在 1× / 2× 之间切，`0` 复位，`Esc` 或点背景关闭

## 安装

Windows + HanaAgent（需至少启动过一次，让 renderer 目录生成）。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1
```

Windows PowerShell 5.1 和 PowerShell 7 都能跑。想先看当前状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Check
```

装完**完全退出 Hana 再启动**（托盘图标也要退干净），然后在输入框粘贴一张图点缩略图试试。

### 它改了什么

只有两个文件，都在 Hana 自己的 renderer 目录里（`~/.hanako/artifacts/renderer/<版本>/`）：

- `modules/draft-image-zoom.js` —— 新增，功能脚本
- `index.html` —— 在 `</body>` 前插一行 `<script src="modules/draft-image-zoom.js" data-hdiz="1"></script>`

不碰打包后的 chunk，不改 Program Files 里的安装目录，不联网，不写用户数据。首次修改前脚本自动把 `index.html` 备份成 `index.html.hdiz.bak`。

### 撤掉 / 还原

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Uninstall   # 撤掉
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1 -Restore     # 出问题时还原
```

卸载会用备份把 `index.html` 恢复成安装前的样子。备份文件保留不动。

## 一个要知道的限制

**Hana 每更新一次，这个功能就会消失一次，需要重跑一次安装脚本。**

原因是官方更新会把 renderer 解包成新的版本目录，`index.html` 被换成新的，注入的那行随之不见。这不是脚本坏了，是补丁的固有代价。脚本每次安装都会自动指向最新的版本目录，所以重跑一条命令就能恢复。

## 已知边界

- 只作用于主窗口。快速对话、手机版、平板版走的是别的入口页，不覆盖。
- 只处理图片和 svg 缩略图，音频和普通文件不管。
- 只取缩略图 `img` 元素上的 `src`；上游如果改成背景图，这里要跟着改。
- 这是本地补丁，不是官方功能。

## 给 Agent 的说明

这个仓库同时是一个 Hana skill，Agent 读到 `SKILL.md` 就能知道什么时候该装、怎么装、怎么排错。`SKILL.md` 描述了完整流程，包括怎么定位 skill 目录、PowerShell 5.1 的编码坑（脚本必须存成 **UTF-8 with BOM**，否则 5.1 会按 ANSI 读成乱码并直接解析失败）、以及 Hana 更新后需要重装这件事。

## 许可

MIT，见 [LICENSE](LICENSE)。
