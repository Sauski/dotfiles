#!/usr/bin/env bash
# Dotfiles Setup Script for macOS/Linux

set -e

echo "Setting up dotfiles..."

# Check required dependencies
echo ""
echo "Checking dependencies..."
missing=""

if ! command -v git &> /dev/null; then
    missing="$missing git"
fi
if ! command -v clang &> /dev/null; then
    missing="$missing clang"
fi

if [ -n "$missing" ]; then
    echo "  Missing:$missing"
    echo "  Install before continuing."
    exit 1
fi
echo "  All dependencies found"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_TARGET="$HOME/.config/nvim"
NEOVIDE_TARGET="$HOME/.config/neovide"
CLAUDE_TARGET="$HOME/.claude"

create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  $name exists at $target"
        read -p "  Replace? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$target"
        else
            echo "  Skipping $name"
            return
        fi
    fi

    mkdir -p "$(dirname "$target")"

    if ln -s "$source" "$target"; then
        echo "  Created: $target -> $source"
    else
        echo "  Failed to create symlink for $name"
        exit 1
    fi
}

create_hardlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  $name exists at $target"
        read -p "  Replace? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$target"
        else
            echo "  Skipping $name"
            return
        fi
    fi

    if ln "$source" "$target"; then
        echo "  Created: $target -> $source"
    else
        echo "  Failed to create hard link for $name"
        exit 1
    fi
}

echo ""
echo "Creating symlinks..."
create_symlink "$DOTFILES_DIR/.config/nvim" "$NVIM_TARGET" "Neovim"
create_symlink "$DOTFILES_DIR/.config/neovide" "$NEOVIDE_TARGET" "Neovide"
create_symlink "$DOTFILES_DIR/.config/git" "$HOME/.config/git" "Git Config"

echo ""
echo "Setting up Claude Code config..."
if [ ! -d "$CLAUDE_TARGET" ]; then
    mkdir -p "$CLAUDE_TARGET"
    echo "  Created Claude directory: $CLAUDE_TARGET"
fi
create_hardlink "$DOTFILES_DIR/claude-config/CLAUDE.md" "$CLAUDE_TARGET/CLAUDE.md" "CLAUDE.md"
create_hardlink "$DOTFILES_DIR/claude-config/settings.local.json" "$CLAUDE_TARGET/settings.local.json" "settings.local.json"

echo ""
echo "Configuring PATH..."

# Detect OS for bin directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    BIN_DIR="$DOTFILES_DIR/bin/macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    BIN_DIR="$DOTFILES_DIR/bin/linux"
else
    echo "  Unsupported OS: $OSTYPE"
    exit 1
fi

if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
else
    SHELL_CONFIG="$HOME/.profile"
fi

if ! grep -q "export PATH=\"$BIN_DIR:\$PATH\"" "$SHELL_CONFIG" 2>/dev/null; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Dotfiles bin directory" >> "$SHELL_CONFIG"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_CONFIG"
    echo "  Added $BIN_DIR to PATH in $SHELL_CONFIG"
    echo "  Restart terminal or run: source $SHELL_CONFIG"
else
    echo "  bin directory already in PATH"
fi

echo ""
echo "Setup complete!"

if ! command -v nvim &> /dev/null; then
    echo ""
    echo "Warning: Neovim not installed."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Install: brew install neovim"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Install: apt install neovim, pacman -S neovim, etc."
    fi
fi
