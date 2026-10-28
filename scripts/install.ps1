# Hana draft image zoom - installer for the skill package.
#
# WHY ASCII ONLY, UTF-8 WITH BOM, CRLF:
# Windows PowerShell 5.1 (powershell.exe) decodes a BOM-less UTF-8 script with
# the system ANSI code page (GBK on zh-CN). A multi-byte character right before a
# newline can swallow that newline, so the following line silently becomes part of
# a comment. That destroys the param block, the request degrades into something
# else, and the caller reports success while nothing happened. Keep this file
# pure ASCII, save it as UTF-8 WITH BOM, keep CRLF endings.
#
# Usage:
#   powershell -NoProfile -File install.ps1                     install
#   powershell -NoProfile -File install.ps1 -Check              status only
#   powershell -NoProfile -File install.ps1 -Uninstall           remove
#   powershell -NoProfile -File install.ps1 -Restore             restore from backup
#   powershell -NoProfile -File install.ps1 -RendererDir "<dir>"  explicit renderer dir
#
# Env fallbacks: HDIZ_ACTION (install|status|uninstall|restore), HDIZ_ROOT.
# The last stdout line is always: STATUS: installed=<bool> version=<v> dir=<path>
param(
  [switch]$Uninstall,
  [switch]$Check,
  [switch]$Restore,
  [string]$RendererDir = '',
  [string]$RendererRoot = '',
  [string]$Action = ''
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$scriptFile = 'draft-image-zoom.js'
$scriptTag = '<script src="modules/draft-image-zoom.js" data-hdiz="1"></script>'
$sourceJs = Join-Path $PSScriptRoot $scriptFile
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Resolve-Action {
  if ($Uninstall) { return 'uninstall' }
  if ($Restore) { return 'restore' }
  if ($Check) { return 'status' }
  if ($Action) { return $Action.Trim().ToLowerInvariant() }
  if ($env:HDIZ_ACTION) { return $env:HDIZ_ACTION.Trim().ToLowerInvariant() }
  return 'install'
}

function Resolve-Root {
  if ($RendererRoot) { return $RendererRoot }
  if ($env:HDIZ_ROOT) { return $env:HDIZ_ROOT }
  return (Join-Path $env:USERPROFILE '.hanako\artifacts\renderer')
}

function Get-Version([string]$dirName) {
  if ($dirName -match '^(\d+\.\d+\.\d+[^-]*(?:-[a-z]+)?)') { return $Matches[1] }
  return $dirName
}

function Get-RendererDir {
  param([string]$explicit, [string]$root)
  if ($explicit) {
    if (-not (Test-Path -LiteralPath (Join-Path $explicit 'index.html'))) {
      throw "no index.html in the given renderer dir: $explicit"
    }
    return (Resolve-Path -LiteralPath $explicit).Path
  }
  if (-not (Test-Path -LiteralPath $root)) {
    throw "renderer root not found: $root (start Hana once, then retry)"
  }
  $candidates = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'index.html') } |
    Sort-Object LastWriteTime -Descending
  if (-not $candidates) { throw "no usable renderer version under: $root" }
  return $candidates[0].FullName
}

function Read-State([string]$dir) {
  $index = Join-Path $dir 'index.html'
  $html = Get-Content -LiteralPath $index -Raw -Encoding UTF8
  $scriptPath = Join-Path $dir ('modules\' + $scriptFile)
  $scriptPresent = Test-Path -LiteralPath $scriptPath
  $injected = $html -match 'data-hdiz="1"'
  return @{
    installed = ($scriptPresent -and $injected)
    scriptPresent = $scriptPresent
    injected = $injected
    version = (Get-Version (Split-Path -Leaf $dir))
    dir = $dir
  }
}

function Write-Status($state) {
  Write-Host ("STATUS: installed=" + $state.installed + " version=" + $state.version + " dir=" + $state.dir)
}

$action = Resolve-Action
$root = Resolve-Root

try {
  switch ($action) {
    'status' {
      $dir = Get-RendererDir -explicit $RendererDir -root $root
      $state = Read-State $dir
      Write-Status $state
      exit 0
    }
    'install' {
      if (-not (Test-Path -LiteralPath $sourceJs)) {
        throw "missing $scriptFile next to this script"
      }
      $dir = Get-RendererDir -explicit $RendererDir -root $root
      $modulesDir = Join-Path $dir 'modules'
      if (-not (Test-Path -LiteralPath $modulesDir)) {
        New-Item -ItemType Directory -Path $modulesDir | Out-Null
      }
      Copy-Item -LiteralPath $sourceJs -Destination (Join-Path $modulesDir $scriptFile) -Force

      $index = Join-Path $dir 'index.html'
      $html = Get-Content -LiteralPath $index -Raw -Encoding UTF8
      if ($html -notmatch 'data-hdiz="1"') {
        $backup = $index + '.hdiz.bak'
        if (-not (Test-Path -LiteralPath $backup)) {
          Copy-Item -LiteralPath $index -Destination $backup -Force
        }
        if ($html -match '</body>') {
          $html = [regex]::Replace($html, '</body>', "    $scriptTag`r`n</body>", 1)
        } else {
          $html = $html + "`r`n" + $scriptTag + "`r`n"
        }
        [System.IO.File]::WriteAllText($index, $html, $utf8NoBom)
      }

      # Read the files back: an unverified "done" is exactly the lie we are fixing.
      $state = Read-State $dir
      if (-not $state.installed) {
        Write-Status $state
        Write-Host 'INSTALL_FAILED: the script tag or the js file is not in place.'
        exit 1
      }
      Write-Status $state
      Write-Host 'Installed. Quit Hana completely (tray too) and start it again.'
      exit 0
    }
    'uninstall' {
      $dir = Get-RendererDir -explicit $RendererDir -root $root
      $index = Join-Path $dir 'index.html'
      $html = Get-Content -LiteralPath $index -Raw -Encoding UTF8
      if ($html -match 'data-hdiz="1"') {
        $html = [regex]::Replace($html, '\s*<script[^>]*data-hdiz="1"[^>]*></script>', '')
        [System.IO.File]::WriteAllText($index, $html, $utf8NoBom)
      }
      $scriptPath = Join-Path $dir ('modules\' + $scriptFile)
      if (Test-Path -LiteralPath $scriptPath) { Remove-Item -LiteralPath $scriptPath -Force }
      $state = Read-State $dir
      Write-Status $state
      Write-Host 'Removed. Quit Hana completely (tray too) and start it again.'
      exit 0
    }
    'restore' {
      $dir = Get-RendererDir -explicit $RendererDir -root $root
      $backup = (Join-Path $dir 'index.html') + '.hdiz.bak'
      if (-not (Test-Path -LiteralPath $backup)) { throw "no backup found: $backup" }
      Copy-Item -LiteralPath $backup -Destination (Join-Path $dir 'index.html') -Force
      $scriptPath = Join-Path $dir ('modules\' + $scriptFile)
      if (Test-Path -LiteralPath $scriptPath) { Remove-Item -LiteralPath $scriptPath -Force }
      $state = Read-State $dir
      Write-Status $state
      Write-Host 'Restored from backup. Quit Hana completely (tray too) and start it again.'
      exit 0
    }
    default {
      Write-Host "BAD_ACTION: unknown action '$action' (use install|status|uninstall|restore)"
      exit 2
    }
  }
} catch {
  Write-Host ('FAILED: ' + (String($_.Exception.Message)).Substring(0, [Math]::Min(200, (String($_.Exception.Message)).Length)))
  exit 1
}
