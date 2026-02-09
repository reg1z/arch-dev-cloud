#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_PATH="$PROJECT_ROOT/output/arch-dev.qcow2"
IMAGE_NAME="arch-dev-$(date +%Y%m%d)"

if ! command -v gcloud &>/dev/null; then
    echo "Error: gcloud CLI is not installed or not in PATH."
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run 'make build' first to create the image."
    exit 1
fi

echo "==> Uploading $IMAGE_PATH to GCP as '$IMAGE_NAME'..."
gcloud compute images import "$IMAGE_NAME" \
    --source-file="$IMAGE_PATH" \
    --os=archlinux \
    --no-guest-environment

echo "==> Upload complete: $IMAGE_NAME"
