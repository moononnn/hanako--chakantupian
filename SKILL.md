---
name: hana-draft-image-zoom
description: "给 Hana 聊天输入框里粘贴/附加的图片缩略图加上点击放大查看。安装一个小脚本到 Hana 的 renderer 目录，点输入框里的图片就能全屏看大图，还支持多图左右切换、滚轮缩放、Esc 关闭，不改 Hana 源码、不动官方安装包。MANDATORY TRIGGERS：输入框图片放大、贴图放大、草稿图片预览、输入框里贴的图看不清、点图片放大、draft image zoom、Hana 输入框图片点不开、把图片放大功能装一下、装草稿图片放大。SOFT TRIGGERS：粘贴的图太小、想确认贴对没、看大图、图片预览补丁。"
metadata:
  author: "moononnn & 小花"
  minAppVersion: "0.82.0"
  icon: "assets/icon.png"
---

# Hana 草稿图片放大

## 这是什么

Hana 的聊天输入框里粘贴或附加图片后，草稿区只显示一个小缩略图，点它没有任何反应。发出去以后消息里的图可以点开，但草稿阶段看不清。

这个 skill 安装一个独立脚本到 Hana 的 renderer 目录，用事件委托接管草稿缩略图的点击：

- 单击缩略图，全屏看大图
- 草稿里有多张图时，左右箭头切换，键盘 ← → 也行
- 滚轮缩放，放大后可以拖动，双击复位，`0` 复位，`Esc` 或点背景关闭

改动只有两个文件：往 `modules/` 放一个 js，往 `index.html` 的 `</body>` 前插一行 script。不碰打包后的 chunk，不改 Program Files 里的安装目录，不联网。

**它会修改 Hana 自己的 renderer 目录**（`~/.hanako/artifacts/renderer/<版本>/`），这是实现方式本身决定的，不是 bug。首次改动前脚本会自动备份 `index.html` 为 `index.html.hdiz.bak`，卸载或还原时用这份备份把文件恢复原样。

## 什么时候用

用户说输入框里贴的图太小看不清、想让草稿图片能点开放大、想把这个功能装到别的机器或分享给群友时。

## 安装步骤

1. 先确认这台机器装过 Hana 并至少启动过一次，`~/.hanako/artifacts/renderer/` 下要有版本目录。

2. 运行同目录的安装脚本。**Windows PowerShell 5.1 和 PowerShell 7 都能跑**，脚本已按 5.1 兼容写好并带 UTF-8 BOM：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>/scripts/install.ps1
```

想先看看当前装没装：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>/scripts/install.ps1 -Check
```

`<skill目录>` 就是本 skill 所在目录：装成 skill 时是 `~/.hanako/skills/hana-draft-image-zoom/`，从仓库直接用就是仓库根目录。找不到确切路径时，先按下面的方式定位再执行：

```powershell
Get-ChildItem -Path "$env:USERPROFILE\.hanako\skills" -Directory -Filter "hana-draft-image-zoom"
```

需要指定特定版本目录时加参数：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>/scripts/install.ps1 -RendererDir "C:\Users\xxx\.hanako\artifacts\renderer\1.1.35-beta-..."
```

脚本会自己找最新的 renderer 版本目录，做这几件事：

- 把 `scripts/draft-image-zoom.js` 复制到 `<renderer>/modules/draft-image-zoom.js`
- 首次修改 `index.html` 前，备份成 `index.html.hdiz.bak`
- 在 `</body>` 前插入 `<script src="modules/draft-image-zoom.js" data-hdiz="1"></script>`
- 已经插过就跳过，重复运行是安全的（不会插第二行）

3. 让用户完全退出 Hana 再启动（托盘图标也要退干净），窗口重新加载后生效。只关窗口不退出进程时，改动不会生效。

4. 验证：在输入框粘贴一张图，点缩略图，应该弹出全屏预览。按 `Esc` 能关掉。

## 排错

**装完点了没反应**
先确认真的完全重启了 Hana，不是只关了窗口。还不行就在开发者工具里看一眼：草稿缩略图的外层元素类名里是否还带 `media-attachment-chip`。上游若改了这个类名，把 `scripts/draft-image-zoom.js` 顶部的 `CHIP_SELECTOR` 改掉再重装。

**Hana 更新后功能消失**
正常，不是故障。每次更新 renderer 会解包成新的版本目录，`index.html` 被换掉，注入行随之消失。重新跑一次安装脚本即可，脚本会自动指向新目录。用户抱怨"又没了"时直接说这个原因。

**想彻底撤掉**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>/scripts/install.ps1 -Uninstall
```

会用备份把 `index.html` 恢复成安装前的样子，删掉注入的 js 文件，备份文件 `index.html.hdiz.bak` 保留不动，需要时可以手动还原。卸载后同样要完全退出并重启 Hana。

**白屏或界面异常**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>/scripts/install.ps1 -Restore
```

这条会从备份还原 `index.html` 并删掉 js 文件，然后完全退出并重启 Hana。

**脚本报乱码或语法错误**
说明脚本文件被存成了无 BOM 的 UTF-8，Windows PowerShell 5.1 会按 ANSI 读它，中文会变成乱码并直接解析失败。重新存一次，编码选「UTF-8 with BOM」，或直接用 PowerShell 7（`pwsh`）执行。

## 已知边界

- 只作用于主窗口（`index.html`）。快速对话、手机版、平板版用的是别的入口页，不覆盖。
- 只处理图片和 svg 缩略图。音频、普通文件那种 chip 不接管。
- 只取草稿缩略图 `img` 元素上的 `src`。如果上游换成背景图或 data 属性，这里要跟着改。
- 这是本地补丁，不是官方功能。每次 Hana 更新后需要重装一次。用户如果想让它长期存在，建议同时把改法反馈给上游，或者接受每次更新后重装一次。
- 分享给群友时，把整个 skill 目录或打好的 `.skill` 包给对方装，不要只发 js 文件，脚本要靠安装器定位目录和改 `index.html`。
