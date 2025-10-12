# Dotfiles Setup Script for Windows

Write-Host "Setting up dotfiles..." -ForegroundColor Green

$DOTFILES_DIR = $PSScriptRoot
$NVIM_TARGET = "$env:LOCALAPPDATA\nvim"
$NEOVIDE_TARGET = "$env:APPDATA\neovide"

function Copy-Config {
    param (
        [string]$Source,
        [string]$Target,
        [string]$Name
    )

    if (Test-Path $Target) {
        Write-Host "  $Name exists at $Target" -ForegroundColor Yellow
        $response = Read-Host "  Replace? (y/n)"
        if ($response -eq 'y') {
            Remove-Item -Path $Target -Recurse -Force
        } else {
            Write-Host "  Skipping $Name" -ForegroundColor Yellow
            return
        }
    }

    $parentDir = Split-Path -Parent $Target
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    Copy-Item -Path $Source -Destination $Target -Recurse -Force
    Write-Host "  Copied: $Source -> $Target" -ForegroundColor Green
}

Write-Host "`nCopying configurations..." -ForegroundColor Cyan
Copy-Config -Source "$DOTFILES_DIR\.config\nvim" -Target $NVIM_TARGET -Name "Neovim"
Copy-Config -Source "$DOTFILES_DIR\.config\neovide" -Target $NEOVIDE_TARGET -Name "Neovide"

Write-Host "`nConfiguring PATH..." -ForegroundColor Cyan
$binDir = "$DOTFILES_DIR\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$binDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binDir", "User")
    Write-Host "  Added $binDir to PATH" -ForegroundColor Green
    Write-Host "  Restart terminal for PATH changes" -ForegroundColor Yellow
} else {
    Write-Host "  bin directory already in PATH" -ForegroundColor Green
}

Write-Host "`nSetup complete!" -ForegroundColor Green
