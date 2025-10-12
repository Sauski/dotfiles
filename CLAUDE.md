# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Dotfiles repository for managing configuration files across development environments.

## Directory Structure

```
.config/
  nvim/           - Neovim configuration
    init.lua      - Main config file
    pack/         - Native Vim 8+ package management (plugins in pack/plugins/start/)
  neovide/        - Neovide GUI configuration
.claude/
  claude.md       - Claude Code configuration (symlinked to user directory)
bin/
  windows/        - Windows binaries (e.g., rg.exe)
  macos/          - macOS binaries
  linux/          - Linux binaries
setup.ps1         - Windows setup script
setup.sh          - macOS/Linux setup script
```

## Setup

**Windows**: `.\setup.ps1` in PowerShell (requires Administrator privileges)
**macOS/Linux**: `./setup.sh` in terminal

Scripts create symlinks to OS-specific locations and add OS-specific `bin/` subdirectory to PATH.

## Neovim Configuration

- **Plugin Management**: Native Vim 8+ package management
- **Leader Key**: Space
- **Tab Settings**: 2 spaces, expanded tabs
- **Plugins**: leap.nvim, telescope.nvim, auto-save.nvim

**Telescope Keybindings**:
- `<leader>f` - Find files
- `<leader>g` - Live grep
- `<leader>b` - Buffers
- `<leader>h` - Help tags

## Adding Plugins

Clone into `.config/nvim/pack/plugins/start/` and add setup call in `init.lua` if needed.
