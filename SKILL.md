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

这个 skill 带一份独立脚本，装进 Hana 的 renderer 目录，用事件委托接管草稿缩略图的点击：

- 单击缩略图，全屏看大图
- 草稿里有多张图时，左右箭头切换，键盘 ← → 也行
- 滚轮缩放，放大后可以拖动，双击复位，`0` 复位，`Esc` 或点背景关闭

改动只有两个文件：往 `modules/` 放一个 js，往 `index.html` 的 `</body>` 前插一行 script。不碰打包后的 chunk，不改 Program Files 里的安装目录，不联网。

**它会修改 Hana 自己的 renderer 目录**（`~/.hanako/artifacts/renderer/<版本>/`），这是实现方式本身决定的，不是 bug。首次改动前脚本会自动备份 `index.html` 为 `index.html.hdiz.bak`，卸载或还原时用这份备份把文件恢复原样。

## 第一件事：先把脚本装上

**用户说「装上」「没生效」「点了没反应」「贴图看不清」时，先跑安装脚本，再回答。** 不要先解释、后让人自己去跑。

技能被装上 ≠ 功能被装上。装技能只是把文件放进 `~/.hanako/skills/hana-draft-image-zoom/`，真正要动 Hana 界面的是下面这个脚本。少了这一步，用户重启一百次也没用。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <技能目录>/scripts/install.ps1
```

`<技能目录>` 就是本技能所在目录：装成技能时是 `~/.hanako/skills/hana-draft-image-zoom/`，从仓库直接用就是仓库根目录。找不到确切路径时先定位：

```powershell
Get-ChildItem -Path "$env:USERPROFILE\.hanako\skills" -Directory -Filter "hana-draft-image-zoom"
```

脚本最后一行是机器可读的状态行，**用它判断成败，不要看它前面那句人话**：

```
STATUS: installed=True version=1.3.6-beta dir=C:\Users\...\renderer\1.3.6-beta-...
```

`installed=True` 才算装上。脚本没装成功时会以退出码 1 结束并打印 `INSTALL_FAILED`，这时照实告诉用户哪里失败，别报成功。

脚本是幂等的：重复跑不会插第二行注入。已经装好时它会直接报 `installed=True`，不用重装。

## 让它真的生效

脚本装好后，需要**完全退出 Hana 再启动**（托盘图标也要退干净）。只关窗口不算，Electron 的 renderer 不会重新加载 `index.html`。这一步必须由用户自己做，程序没法替他关掉自己正在跑的会话。

装完告诉用户两件事：贴一张图到输入框，点缩略图应该弹出全屏预览；`Esc` 能关掉。

## 排错

**装了没反应**
先确认真的完全重启了 Hana，不是只关了窗口。重启后仍然没反应，在开发者工具里看一眼：草稿缩略图的外层元素类名里是否还带 `media-attachment-chip`。上游若改了这个类名，改 `scripts/draft-image-zoom.js` 顶部的 `CHIP_SELECTOR` 再重装。

**脚本跑完什么都没变**
多半是脚本文件被改坏了编码。Windows PowerShell 5.1 按系统 ANSI 代码页（中文系统是 GBK）读没有 BOM 的 UTF-8 脚本，注释里最后一个汉字会把后面的换行吃掉，于是下一行被并进注释、`param()` 块凭空消失、请求悄悄变成别的动作。守住三条：**脚本纯 ASCII、保存成 UTF-8 with BOM、换行用 CRLF**。改完跑一次 `-Check` 就能看出来。

**Hana 更新后功能消失**
正常，不是故障。每次更新 renderer 会解包成新的版本目录，`index.html` 被换掉，注入行随之消失。重新跑一次安装脚本即可，脚本会自动指向新目录。用户抱怨「又没了」时直接说这个原因。

**想彻底撤掉**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <技能目录>/scripts/install.ps1 -Uninstall
```

会用备份把 `index.html` 恢复成安装前的样子，删掉注入的 js 文件，备份文件 `index.html.hdiz.bak` 保留不动，需要时可以手动还原。卸载后同样要完全退出并重启 Hana。

**界面异常（白屏等）**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <技能目录>/scripts/install.ps1 -Restore
```

这条会从备份还原 `index.html` 并删掉 js 文件，然后完全退出并重启 Hana。

**只想看看装没装**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <技能目录>/scripts/install.ps1 -Check
```

## 已知边界

- 只作用于主窗口（`index.html`）。快速对话、手机版、平板版用的是别的入口页，不覆盖。
- 只处理图片和 svg 缩略图。音频、普通文件那种 chip 不接管。
- 只取草稿缩略图 `img` 元素上的 `src`。如果上游换成背景图或 data 属性，这里要跟着改。
- 这是本地补丁，不是官方功能。每次 Hana 更新后需要重装一次。用户如果想让它长期存在，建议同时把改法反馈给上游，或者接受每次更新后重装一次。

## 分享给群友

把整个技能目录或打好的 `.skill` 包给对方装，不要只发 js 文件——脚本要靠安装器定位目录、改 `index.html`，单发 js 装不上。

对方装好技能后，**还要让他跟 Hana 说一句「把贴图放大装上」**，由 Hana 跑一次安装脚本；脚本装好后完全退出并重启 Hana 一次，贴图点缩略图就能放大。
