#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_PATH="$PROJECT_ROOT/output/arch-dev.qcow2"
VHD_PATH="$PROJECT_ROOT/output/arch-dev.vhd"
IMAGE_NAME="arch-dev-$(date +%Y%m%d)"

if ! command -v az &>/dev/null; then
    echo "Error: az CLI is not installed or not in PATH."
    echo "Install it from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v qemu-img &>/dev/null; then
    echo "Error: qemu-img is not installed or not in PATH."
    echo "Install it with your package manager (e.g., pacman -S qemu-img)."
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run 'make build' first to create the image."
    exit 1
fi

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:?Set AZURE_RESOURCE_GROUP to the target resource group}"

echo "==> Converting QCOW2 to VHD..."
qemu-img convert -f qcow2 -O vpc -o subformat=fixed,force_size "$IMAGE_PATH" "$VHD_PATH"

echo "==> Creating Azure image..."
az image create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$IMAGE_NAME" \
    --os-type Linux \
    --source "$VHD_PATH"

echo "==> Upload complete: $IMAGE_NAME"
echo "==> Cleaning up VHD..."
rm -f "$VHD_PATH"
