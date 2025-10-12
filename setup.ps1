# Dotfiles Setup Script for Windows

param(
    [string]$OriginalUser,
    [string]$OriginalLocalAppData,
    [string]$OriginalAppData,
    [string]$OriginalDotfilesDir
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges for symlink creation..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $currentLocalAppData = $env:LOCALAPPDATA
    $currentAppData = $env:APPDATA
    $currentDotfilesDir = $PSScriptRoot

    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -OriginalUser `"$currentUser`" -OriginalLocalAppData `"$currentLocalAppData`" -OriginalAppData `"$currentAppData`" -OriginalDotfilesDir `"$currentDotfilesDir`""
    exit
}

Write-Host "Setting up dotfiles..." -ForegroundColor Green

# Use passed parameters if running as admin, otherwise use current environment
if ($OriginalDotfilesDir) {
    $DOTFILES_DIR = $OriginalDotfilesDir
    $NVIM_TARGET = "$OriginalLocalAppData\nvim"
    $NEOVIDE_TARGET = "$OriginalAppData\neovide"
    Write-Host "Running as administrator for user: $OriginalUser" -ForegroundColor Cyan
} else {
    $DOTFILES_DIR = $PSScriptRoot
    $NVIM_TARGET = "$env:LOCALAPPDATA\nvim"
    $NEOVIDE_TARGET = "$env:APPDATA\neovide"
}

function Create-Symlink {
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

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Write-Host "  Created: $Target -> $Source" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to create symlink for $Name" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nCreating symlinks..." -ForegroundColor Cyan
Create-Symlink -Source "$DOTFILES_DIR\.config\nvim" -Target $NVIM_TARGET -Name "Neovim"
Create-Symlink -Source "$DOTFILES_DIR\.config\neovide" -Target $NEOVIDE_TARGET -Name "Neovide"

Write-Host "`nConfiguring PATH..." -ForegroundColor Cyan
$binDir = "$DOTFILES_DIR\bin"

# Get user's PATH (not admin's PATH)
if ($OriginalUser) {
    try {
        $userSid = (New-Object System.Security.Principal.NTAccount($OriginalUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $currentPath = (Get-ItemProperty -Path "Registry::HKEY_USERS\$userSid\Environment" -Name Path -ErrorAction SilentlyContinue).Path
    } catch {
        Write-Host "  Failed to access user registry, using direct registry path" -ForegroundColor Yellow
        # Fallback: find the user's SID by username without domain
        $username = $OriginalUser.Split('\')[-1]
        $userProfile = Get-WmiObject Win32_UserProfile | Where-Object { $_.LocalPath -like "*\$username" }
        if ($userProfile) {
            $userSid = $userProfile.SID
            $currentPath = (Get-ItemProperty -Path "Registry::HKEY_USERS\$userSid\Environment" -Name Path -ErrorAction SilentlyContinue).Path
        } else {
            Write-Host "  Could not find user SID, skipping PATH update" -ForegroundColor Red
            $userSid = $null
        }
    }
} else {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
}

if ($currentPath -notlike "*$binDir*") {
    if ($OriginalUser -and $userSid) {
        try {
            Set-ItemProperty -Path "Registry::HKEY_USERS\$userSid\Environment" -Name Path -Value "$currentPath;$binDir"
            Write-Host "  Added $binDir to PATH" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to update PATH in registry: $_" -ForegroundColor Red
        }
    } else {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binDir", "User")
        Write-Host "  Added $binDir to PATH" -ForegroundColor Green
    }
    Write-Host "  Restart terminal for PATH changes" -ForegroundColor Yellow
} else {
    Write-Host "  bin directory already in PATH" -ForegroundColor Green
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Read-Host "Press Enter to exit"
