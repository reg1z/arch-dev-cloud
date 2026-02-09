#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

IMAGE_PATH="$PROJECT_ROOT/output/build/arch-dev.qcow2"
IMAGE_NAME="arch-dev-$(date +%Y%m%d)"

for cmd in gcloud gsutil qemu-img; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed or not in PATH."
        exit 1
    fi
done

GCP_PROJECT="${GCP_PROJECT:?Error: GCP_PROJECT environment variable must be set}"
GCS_BUCKET="${GCS_BUCKET:?Error: GCS_BUCKET environment variable must be set (e.g. gs://your-bucket)}"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run 'make build' first to create the image."
    exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Converting qcow2 to raw..."
qemu-img convert -f qcow2 -O raw "$IMAGE_PATH" "$WORK_DIR/disk.raw"

echo "==> Compressing raw image..."
tar -czf "$WORK_DIR/$IMAGE_NAME.tar.gz" -C "$WORK_DIR" disk.raw

echo "==> Uploading to $GCS_BUCKET/$IMAGE_NAME.tar.gz..."
gsutil cp "$WORK_DIR/$IMAGE_NAME.tar.gz" "$GCS_BUCKET/$IMAGE_NAME.tar.gz"

echo "==> Creating GCP image '$IMAGE_NAME'..."
gcloud compute images create "$IMAGE_NAME" \
    --project="$GCP_PROJECT" \
    --source-uri="$GCS_BUCKET/$IMAGE_NAME.tar.gz" \
    --guest-os-features=VIRTIO_SCSI_MULTIQUEUE,UEFI_COMPATIBLE,GVNIC

echo "==> Upload complete: $IMAGE_NAME"
