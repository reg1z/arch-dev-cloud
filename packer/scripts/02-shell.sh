#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing zsh and tmux..."
pacman -S --noconfirm --needed zsh tmux

ARCH_HOME="/home/arch"

echo "==> Installing oh-my-zsh..."
su - arch -c '
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
'

echo "==> Configuring vi-mode plugin..."
sed -i 's/^plugins=.*/plugins=(vi-mode)/' "$ARCH_HOME/.zshrc"

echo "==> Setting zsh as default shell..."
chsh -s /usr/bin/zsh arch

echo "==> 02-shell.sh complete"
