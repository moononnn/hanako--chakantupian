# 上架 Hana 官方市场 · 登记清单

包已经打好、Release 也发好了，这一页剩下的是提市场 PR 那几步。

## 已完成

| 项 | 值 |
|---|---|
| 仓库 | https://github.com/moononnn/hanako--chakantupian |
| Release | https://github.com/moononnn/hanako--chakantupian/releases/tag/v1.0.0 |
| 入口条目附件 | `skill-hana-draft-image-zoom.entry.json` |
| 安装包附件 | `skill-hana-draft-image-zoom-e388d163ff936f884a48720095c062e97712a943ee7429a2a496627153ddd588.zip` |
| `archive.sha256` | `e388d163ff936f884a48720095c062e97712a943ee7429a2a496627153ddd588` |
| `archive.size` | `31242` |
| publisher | `moononnn & 小花` |
| kind / id | `skill` / `hana-draft-image-zoom` |

回下载核验已做：从 Release 拉回 zip 重算 SHA-256，与 entry.json 逐位一致，大小一致。zip 结构为无顶层目录的 5 个文件：`SKILL.md` / `LICENSE` / `assets/icon.png` / `scripts/draft-image-zoom.js` / `scripts/install.ps1`。

> 仓库名以作者建的 `hanako--chakantupian` 为准；市场条目里的 skill id 仍是 `hana-draft-image-zoom`——id 由包内容决定，与仓库名无关，所以搬家不影响登记。

已确认：市场里没有本 id 的重复登记，也没有针对本 id 的 open PR。

## 还差：提市场 PR

### 1. 拉市场仓库，从上游拉分支

```bash
git clone https://github.com/moononnn/hana-marketplace.git
cd hana-marketplace
git remote add upstream https://github.com/liliMozi/hana-marketplace.git
git fetch upstream
git checkout -b register/hana-draft-image-zoom-v1.0.0 upstream/main
```

**必须从 `upstream/main` 拉分支**，不要用 fork 的 main（fork 会静默落后上游，差一个版本号就会把中间那版从目录里抹掉）。

### 2. 改 `registry.json`

在 `entries` 数组追加：

```json
{
  "kind": "skill",
  "id": "hana-draft-image-zoom",
  "repository": "moononnn/hanako--chakantupian",
  "publisher": "moononnn & 小花"
}
```

### 3. 改 `approvals.json`

在 `approvals` 数组追加：

```json
{
  "kind": "skill",
  "id": "hana-draft-image-zoom",
  "tag": "v1.0.0",
  "sha256": "e388d163ff936f884a48720095c062e97712a943ee7429a2a496627153ddd588",
  "readme": "<把 market-readme.md 的全文贴进来>"
}
```

`readme` 上限 2 MiB，市场介绍不加载远程图片。

### 4. 自查

```bash
gh api repos/liliMozi/hana-marketplace/contents/approvals.json --jq '.content'
```

对一下远端现值再改，别信本地文件。

### 5. 提 PR

推分支到自己的 fork，再对 `liliMozi/hana-marketplace` 开 PR。**一个 PR 只登记一个扩展**，不要手工改 `index.v2.json`。

PR 正文按仓库模板填这四栏：

- **基本信息**：名称「草稿图片放大 · 点一下看大图」、类型 skill、ID `hana-draft-image-zoom`、发布者 `moononnn & 小花`、用途、仓库与 Release 链接
- **图标预览**：把 `assets/icon.png` 拖进 PR 正文框，或插入 https://github.com/moononnn/hanako--chakantupian/raw/main/assets/icon.png
- **截图或演示**：贴一张「点缩略图弹出全屏预览」的图；没有现成截图就明说没贴
- **自测报告**：见下
- **权限与外部服务**：无

自测报告可用的内容：

- Hana 版本：1.2.1-beta（Windows x64）
- 操作系统：Windows
- 安装测试使用的 Release：v1.0.0
- 步骤：解压安装包 → 放进 skills 下名为 `hana-draft-image-zoom` 的目录 → 完全退出并重启 Hana → 输入框粘贴图片 → 点缩略图
- 实际结果：弹出全屏预览，多图可左右切换，滚轮缩放正常，`Esc` 可关闭
- 已测：安装脚本幂等重跑（注入行仍为 1 行）、`-Check` 状态检查、`-Uninstall` 卸载后 `index.html` 与安装前字节一致、`-Restore` 还原；Windows PowerShell 5.1 与 PowerShell 7 双环境
- 未测试：快速对话 / 手机版 / 平板版入口（不覆盖）；非 Windows 平台
- 已知问题：Hana 每次更新后需重跑一次安装脚本

### 6. 等审核

维护者审这个具体的包，合并后发布工作流更新 `index.v2.json`，客户端才刷得出条目。**合并 ≠ 上架**，要看目录里真的出现才算数。之后每次改版本都要再走一遍 PR。

## 改版本时

重新打包时，skill 的版本号固定是 `0.0.0`，靠内容哈希区分新旧；zip 文件名里的哈希会变，登记时要同步更新 `approvals.json` 里的 `sha256` 与 `tag`。
