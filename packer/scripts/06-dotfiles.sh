#!/usr/bin/env bash
set -euo pipefail

ARCH_HOME="/home/arch"

echo "==> Installing tmux config..."
mkdir -p "$ARCH_HOME/.config/tmux"
cp /tmp/dots/tmux/tmux.conf "$ARCH_HOME/.config/tmux/tmux.conf"
chown arch:arch "$ARCH_HOME/.config/tmux/tmux.conf"

echo "==> Installing shell config files..."
mkdir -p "$ARCH_HOME/.config/shell"
cp /tmp/dots/shell/aliases   "$ARCH_HOME/.config/shell/aliases"
cp /tmp/dots/shell/tmux_fns  "$ARCH_HOME/.config/shell/tmux_fns"
chown arch:arch "$ARCH_HOME/.config/shell/aliases" "$ARCH_HOME/.config/shell/tmux_fns"

echo "==> Installing .zshrc..."
cp /tmp/dots/shell/.zshrc "$ARCH_HOME/.zshrc"
chown arch:arch "$ARCH_HOME/.zshrc"

echo "==> Installing .bashrc..."
cp /tmp/dots/shell/.bashrc "$ARCH_HOME/.bashrc"
chown arch:arch "$ARCH_HOME/.bashrc"

echo "==> Installing nvim config..."
# LazyVim starter was already cloned in 03-editor.sh; overwrite the config stubs
mkdir -p "$ARCH_HOME/.config/nvim/lua/config"
cp -r /tmp/dots/nvim/lua "$ARCH_HOME/.config/nvim/"
chown -R arch:arch "$ARCH_HOME/.config/nvim/lua"

echo "==> 06-dotfiles.sh complete"
