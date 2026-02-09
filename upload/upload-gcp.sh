#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_PATH="$PROJECT_ROOT/output/build/arch-dev.qcow2"
IMAGE_NAME="arch-dev-$(date +%Y%m%d)"

if ! command -v gcloud &>/dev/null; then
    echo "Error: gcloud CLI is not installed or not in PATH."
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v gsutil &>/dev/null; then
    echo "Error: gsutil is not installed or not in PATH."
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

GCS_BUCKET="${GCS_BUCKET:?Error: GCS_BUCKET environment variable must be set (e.g. gs://your-bucket)}"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run 'make build' first to create the image."
    exit 1
fi

echo "==> Uploading $IMAGE_PATH to $GCS_BUCKET/$IMAGE_NAME.qcow2..."
gsutil cp "$IMAGE_PATH" "$GCS_BUCKET/$IMAGE_NAME.qcow2"

echo "==> Creating GCP image '$IMAGE_NAME'..."
gcloud compute images create "$IMAGE_NAME" \
    --source-uri="$GCS_BUCKET/$IMAGE_NAME.qcow2" \
    --guest-os-features=VIRTIO_SCSI_MULTIQUEUE,UEFI_COMPATIBLE,GVNIC

echo "==> Upload complete: $IMAGE_NAME"
