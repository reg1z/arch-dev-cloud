#!/usr/bin/env bash
set -euo pipefail

echo "==> Cleaning pacman cache..."
pacman -Scc --noconfirm

echo "==> Cleaning npm cache..."
su - arch -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    npm cache clean --force 2>/dev/null || true
'

echo "==> Cleaning yay cache..."
su - arch -c '
    yay -Scc --noconfirm 2>/dev/null || true
'

echo "==> Removing build user..."
userdel -r builduser 2>/dev/null || true
rm -f /etc/sudoers.d/builduser

echo "==> Clearing temp files..."
rm -rf /tmp/* /var/tmp/*

echo "==> 99-cleanup.sh complete"
