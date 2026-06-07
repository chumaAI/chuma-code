# Chuma Windows installer
# Usage: iwr https://raw.githubusercontent.com/Chatelo/Model-Plug/main/scripts/install.ps1 | iex
#        or: $env:CHUMA_VERSION="0.9.0"; iwr ... | iex

$ErrorActionPreference = "Stop"

$Repo = "chumaAI/chuma-code"
$Binary  = "chuma"
$Version = if ($env:CHUMA_VERSION) { $env:CHUMA_VERSION } else { "latest" }

Write-Host ""
Write-Host "╔══════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Chuma ⚡  Installer        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── detect arch ─────────────────────────────────────────────────────────────
$Arch = if ([System.Environment]::Is64BitOperatingSystem) {
  if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
} else {
  Write-Host "✗ 32-bit Windows is not supported." -ForegroundColor Red; exit 1
}

# ── resolve version ──────────────────────────────────────────────────────────
if ($Version -eq "latest") {
  Write-Host "▶ Fetching latest release..." -ForegroundColor Cyan
  $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
  $Version = $Release.tag_name
}

Write-Host "▶ Installing $Binary $Version (windows/$Arch)" -ForegroundColor Cyan

# ── download ─────────────────────────────────────────────────────────────────
# Asset shape produced by .github/workflows/release.yml (Windows arm):
#   chuma-windows-<arch>-v<VERSION>.zip
# Keep in lockstep with that matrix.
$Zip     = "$Binary-windows-$Arch-$Version.zip"
$Url     = "https://github.com/$Repo/releases/download/$Version/$Zip"
$TmpDir  = Join-Path $env:TEMP "chuma-install-$(Get-Random)"
New-Item -ItemType Directory -Path $TmpDir | Out-Null

Write-Host "▶ Downloading $Url" -ForegroundColor Green
try {
  Invoke-WebRequest -Uri $Url -OutFile (Join-Path $TmpDir $Zip) -UseBasicParsing
} catch {
  Write-Host "✗ Download failed: $_" -ForegroundColor Red
  Write-Host "  URL: $Url"
  exit 1
}

Write-Host "▶ Extracting..." -ForegroundColor Green
Expand-Archive -Path (Join-Path $TmpDir $Zip) -DestinationPath $TmpDir -Force

# ── install ───────────────────────────────────────────────────────────────────
$InstallDir = if ($env:CHUMA_INSTALL_DIR) {
  $env:CHUMA_INSTALL_DIR
} else {
  Join-Path $env:USERPROFILE ".local\bin"
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$Dest = Join-Path $InstallDir "$Binary.exe"
Move-Item -Path (Join-Path $TmpDir "$Binary.exe") -Destination $Dest -Force

# ── PATH check ────────────────────────────────────────────────────────────────
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$InstallDir*") {
  [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$UserPath", "User")
  Write-Host ""
  Write-Host "⚠  Added $InstallDir to your user PATH." -ForegroundColor Yellow
  Write-Host "   Restart your terminal for it to take effect."
}

# ── done ──────────────────────────────────────────────────────────────────────
$InstalledVersion = & $Dest --version 2>$null
Write-Host ""
Write-Host "✓ Chuma installed!" -ForegroundColor Green
Write-Host "  Location : $Dest"
Write-Host "  Version  : $InstalledVersion"
Write-Host ""
Write-Host "Quick start:"
Write-Host "  chuma config setup" -ForegroundColor Cyan #— prompts for providers setup, including API keys if needed
Write-Host "  chuma status" -ForegroundColor Cyan
Write-Host "  cd to your project directory"
Write-Host "  chuma"

Remove-Item -Recurse -Force $TmpDir