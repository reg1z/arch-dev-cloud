#!/usr/bin/env bash
set -euo pipefail

echo "==> Initializing Packer plugins..."
packer init /packer/arch-dev.pkr.hcl

echo "==> Running Packer build..."
packer build /packer/arch-dev.pkr.hcl

echo "==> Build complete. Image available in /output/"
