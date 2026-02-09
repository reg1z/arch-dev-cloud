#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing neovim..."
pacman -S --noconfirm --needed neovim

ARCH_HOME="/home/arch"

echo "==> Cloning LazyVim starter config..."
su - arch -c '
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
'

echo "==> Triggering LazyVim plugin installation..."
su - arch -c '
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
'

echo "==> 03-editor.sh complete"
