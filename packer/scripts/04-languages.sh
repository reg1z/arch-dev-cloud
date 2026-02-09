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

echo "==> 04-languages.sh complete"
