#!/usr/bin/env bash
set -euo pipefail

echo "==> Upgrading system packages..."
pacman -Syu --noconfirm

echo "==> Installing base-devel and git..."
pacman -S --noconfirm --needed base-devel git

echo "==> Creating build user for AUR packages..."
useradd -m -G wheel builduser
echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser

echo "==> Installing yay..."
su - builduser -c '
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
'
rm -rf /tmp/yay

echo "==> 01-base.sh complete"
