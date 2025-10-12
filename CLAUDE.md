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
bin/              - Utility binaries
setup.ps1         - Windows setup script
setup.sh          - macOS/Linux setup script
```

## Setup

**Windows**: `.\setup.ps1` in PowerShell
**macOS/Linux**: `./setup.sh` in terminal

Scripts copy configurations to OS-specific locations and add `bin/` to PATH.

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
