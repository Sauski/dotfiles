# Dotfiles

Configuration files for development environments.

## Directory Structure

```
.config/
  nvim/           - Neovim configuration
    init.lua      - Main config file
    pack/         - Native Vim 8+ package management (plugins in pack/plugins/start/)
  neovide/        - Neovide GUI configuration
claude-config/
  CLAUDE.md       - Claude Code global instructions
  settings.local.json - Claude Code settings
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

Scripts create symlinks for config directories and hard links for Claude Code config files to OS-specific locations. Adds OS-specific `bin/` subdirectory to PATH.

### What Gets Linked

- **Neovim**: `.config/nvim` → `~/.config/nvim` (symlink)
- **Neovide**: `.config/neovide` → `~/.config/neovide` (Windows) or `~/.config/neovide` (macOS/Linux) (symlink)
- **Claude Code**: `claude-config/CLAUDE.md` → `~/.claude/CLAUDE.md` (hard link)
- **Claude Code**: `claude-config/settings.local.json` → `~/.claude/settings.local.json` (hard link)

Hard links ensure Claude Code config is tracked in git while operational data (history, debug logs) stays local.

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
