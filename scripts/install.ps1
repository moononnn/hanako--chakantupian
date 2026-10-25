<#
  草稿图片放大 · 安装 / 卸载 / 状态检查脚本
  兼容 Windows PowerShell 5.1 与 PowerShell 7+。

  用法：
    安装：        powershell -NoProfile -File install.ps1
    卸载：        powershell -NoProfile -File install.ps1 -Uninstall
    状态检查：    powershell -NoProfile -File install.ps1 -Check
    指定目录：    powershell -NoProfile -File install.ps1 -RendererDir "C:\Users\xxx\.hanako\artifacts\renderer\1.1.35-beta-..."

  做的事：把 draft-image-zoom.js 放进 renderer 的 modules\ 目录，并在 index.html 的
  </body> 前插一行 script 标签。只改这两个文件；index.html 首次改动会留备份，
  可用 -Restore 从备份还原。
#>
param(
  [switch]$Uninstall,
  [switch]$Check,
  [switch]$Restore,
  [string]$RendererDir = ""
)

$ErrorActionPreference = 'Stop'

$scriptTag  = '<script src="modules/draft-image-zoom.js" data-hdiz="1"></script>'
$scriptFile = 'draft-image-zoom.js'
$targetRel  = 'modules\draft-image-zoom.js'
$sourceJs   = Join-Path $PSScriptRoot $scriptFile
$utf8NoBom  = New-Object System.Text.UTF8Encoding($false)

function Get-RendererDir {
  param([string]$explicit)
  if ($explicit) {
    if (-not (Test-Path -LiteralPath (Join-Path $explicit 'index.html'))) {
      throw "指定目录里没有 index.html：$explicit"
    }
    return (Resolve-Path -LiteralPath $explicit).Path
  }

  $root = Join-Path $env:USERPROFILE '.hanako\artifacts\renderer'
  if (-not (Test-Path -LiteralPath $root)) {
    throw "找不到 renderer 目录：$root（Hana 可能还没启动过一次）"
  }

  $candidates = Get-ChildItem -LiteralPath $root -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'index.html') } |
    Sort-Object LastWriteTime -Descending

  if (-not $candidates) { throw "renderer 目录里没有可用版本：$root" }
  return $candidates[0].FullName
}

$renderer = Get-RendererDir -explicit $RendererDir
$indexPath    = Join-Path $renderer 'index.html'
$targetJs     = Join-Path $renderer $targetRel
$backupPath   = Join-Path $renderer 'index.html.hdiz.bak'
$versionName  = Split-Path -Leaf $renderer

$html = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
$hasTag = $html -match 'data-hdiz="1"'
$hasJs  = Test-Path -LiteralPath $targetJs

function Write-Status {
  param([string]$Label, [string]$Value)
  Write-Host ("{0}：{1}" -f $Label, $Value)
}

# ---------- 状态检查 ----------
if ($Check) {
  Write-Host ''
  Write-Status 'renderer' $renderer
  Write-Status '版本目录' $versionName
  Write-Status '注入标签' $(if ($hasTag) { '已注入' } else { '未注入' })
  Write-Status '脚本文件' $(if ($hasJs) { '已就位' } else { '缺失' })
  Write-Status '备份文件' $(if (Test-Path -LiteralPath $backupPath) { $backupPath } else { '无' })
  Write-Status '当前状态' $(if ($hasTag -and $hasJs) { '已安装' } else { '未安装' })
  if (-not $hasTag -or -not $hasJs) {
    Write-Host ''
    Write-Host '如需安装：powershell -NoProfile -File install.ps1'
  }
  Write-Host ''
  exit 0
}

# ---------- 还原 ----------
if ($Restore) {
  if (-not (Test-Path -LiteralPath $backupPath)) {
    throw "找不到备份：$backupPath"
  }
  Copy-Item -LiteralPath $backupPath -Destination $indexPath -Force
  Write-Host "已从备份还原：$indexPath"
  if (Test-Path -LiteralPath $targetJs) {
    Remove-Item -LiteralPath $targetJs -Force
    Write-Host "已删除脚本：$targetJs"
  }
  Write-Host '还原完成。完全退出 Hana 再启动。'
  exit 0
}

# ---------- 卸载 ----------
if ($Uninstall) {
  if (Test-Path -LiteralPath $backupPath) {
    # 有备份就整份还原，保证卸载后 index.html 与安装前一模一样
    Copy-Item -LiteralPath $backupPath -Destination $indexPath -Force
    Write-Host "已用备份还原 index.html：$indexPath"
  } elseif ($hasTag) {
    $html = [regex]::Replace($html, '\s*<script[^>]*data-hdiz="1"[^>]*></script>', '')
    [System.IO.File]::WriteAllText($indexPath, $html, $utf8NoBom)
    Write-Host "已从 index.html 移除注入行：$indexPath"
  } else {
    Write-Host 'index.html 里没有注入行，也没有备份，跳过。'
  }
  if ($hasJs) {
    Remove-Item -LiteralPath $targetJs -Force
    Write-Host "已删除脚本：$targetJs"
  }
  Write-Host '卸载完成。完全退出 Hana 再启动（托盘也要退）。'
  exit 0
}

# ---------- 安装 ----------
if (-not (Test-Path -LiteralPath $sourceJs)) {
  throw "同目录下找不到 $scriptFile，请把两个文件放在一起。"
}

# 1. 放脚本
$modulesDir = Join-Path $renderer 'modules'
if (-not (Test-Path -LiteralPath $modulesDir)) {
  New-Item -ItemType Directory -Path $modulesDir | Out-Null
}
Copy-Item -LiteralPath $sourceJs -Destination $targetJs -Force
Write-Host "已复制脚本：$targetJs"

# 2. 改 index.html（幂等）
if ($hasTag) {
  Write-Host 'index.html 已有注入行，跳过。'
} else {
  if (-not (Test-Path -LiteralPath $backupPath)) {
    Copy-Item -LiteralPath $indexPath -Destination $backupPath -Force
    Write-Host "已备份：$backupPath"
  }

  if ($html -match '</body>') {
    $html = [regex]::Replace($html, '</body>', "    $scriptTag`r`n</body>", 1)
  } else {
    $html = $html + "`r`n" + $scriptTag + "`r`n"
  }

  [System.IO.File]::WriteAllText($indexPath, $html, $utf8NoBom)
  Write-Host "已注入 index.html：$indexPath"
}

Write-Host ''
Write-Host "安装完成（renderer 版本目录：$versionName）。"
Write-Host '完全退出 Hana 再启动（托盘图标也要退干净），然后在输入框粘贴一张图点缩略图试试。'
Write-Host '不想要了就运行：powershell -NoProfile -File install.ps1 -Uninstall'
Write-Host '出问题了可以还原：powershell -NoProfile -File install.ps1 -Restore'
