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

### Plugins

**leap.nvim** - Motion plugin for jumping to any location
- `s` - Jump anywhere (all windows)
- `S` - Jump in current window only

**telescope.nvim** - Fuzzy finder
- `<leader>f` - Find files
- `<leader>g` - Live grep
- `<leader>b` - Buffers
- `<leader>h` - Help tags
- `<leader>e` - Diagnostics

**nvim-treesitter** - Syntax highlighting and code parsing

**auto-save.nvim** - Automatically saves files on buffer changes

**auto-session** - Automatic session persistence per directory
- Sessions saved to `~/.local/share/nvim/sessions/`
- Session created per working directory (cwd)
- **Important**: Opening nvim with file arguments (e.g., clicking a file in Windows) prevents session creation/restore. Open nvim without args to use sessions.
- `<leader>s` - Search and switch sessions

**quickbuild** - Build automation
- `<leader>bb` - Run build
- `<leader>bc` - Cancel build

**clang-format** - C/C++ code formatting (Chromium style)
- `<leader>w` - Format and save

## Adding Plugins

Clone into `.config/nvim/pack/plugins/start/` and add setup call in `init.lua` if needed.
