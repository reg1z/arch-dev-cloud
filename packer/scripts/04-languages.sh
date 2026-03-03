#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Python..."
pacman -S --noconfirm --needed python python-pip python-virtualenv

ARCH_HOME="/home/arch"
NVM_VERSION="v0.40.1"

echo "==> Installing nvm..."
su - arch -c "
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
"

echo "==> Installing Node.js 24 LTS via nvm..."
su - arch -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install 24
    nvm alias default 24
'

echo "==> Installing Rust..."
su - arch -c '
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
'

echo "==> Installing rtk..."
su - arch -c '
    source "$HOME/.cargo/env"
    cargo install --git https://github.com/rtk-ai/rtk
'

echo "==> 04-languages.sh complete"
