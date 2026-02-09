#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_PATH="$PROJECT_ROOT/output/arch-dev.qcow2"
IMAGE_NAME="arch-dev-$(date +%Y%m%d)"

if ! command -v aws &>/dev/null; then
    echo "Error: aws CLI is not installed or not in PATH."
    echo "Install it from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run 'make build' first to create the image."
    exit 1
fi

S3_BUCKET="${AWS_IMAGE_BUCKET:?Set AWS_IMAGE_BUCKET to an S3 bucket for staging the image}"

echo "==> Uploading image to S3 staging bucket..."
aws s3 cp "$IMAGE_PATH" "s3://$S3_BUCKET/$IMAGE_NAME.qcow2"

echo "==> Importing image as AMI..."
IMPORT_TASK_ID=$(aws ec2 import-image \
    --description "$IMAGE_NAME" \
    --disk-containers "Description=$IMAGE_NAME,Format=qcow2,UserBucket={S3Bucket=$S3_BUCKET,S3Key=$IMAGE_NAME.qcow2}" \
    --query 'ImportTaskId' \
    --output text)

echo "==> Import task started: $IMPORT_TASK_ID"
echo "==> Monitor with: aws ec2 describe-import-image-tasks --import-task-ids $IMPORT_TASK_ID"
