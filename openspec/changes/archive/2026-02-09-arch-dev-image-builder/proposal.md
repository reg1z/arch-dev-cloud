## Why

Setting up a development environment on a cloud VM is a manual, time-consuming process that's difficult to reproduce. Each new machine requires installing and configuring dozens of tools — shell, editor, language runtimes, AI coding agents, security tools — before any real work can begin. This project creates a reproducible, cloud-agnostic dev environment that can be built locally and deployed to any cloud provider in under a minute.

## What Changes

- Add a containerized build system (Docker + QEMU + Packer) that produces a fully provisioned Arch Linux VM image from the official arch-boxes cloud image
- Add Packer template using the QEMU builder to run provisioning scripts locally, outputting a QCOW2 image
- Add provisioning scripts that install and configure the dev stack: yay, zsh/oh-my-zsh (vi-mode plugin), tmux, neovim/lazyvim, python3, nvm/node, claude-code, opencode
- Add per-provider upload scripts (GCP, AWS, Azure) to push the built QCOW2 to cloud providers
- Add Terraform configurations per cloud provider to deploy VMs from the custom image
- Add cloud-init user-data for runtime personalization: SSH keys, git config, secrets injection, repo cloning
- Add a Makefile as the user-facing interface (`make build`, `make upload-gcp`, `make deploy-gcp`)

## Capabilities

### New Capabilities
- `image-build`: Containerized build environment (Dockerfile) and Packer template for producing Arch Linux dev VM images locally via QEMU
- `provisioning`: Shell scripts that install and configure the dev tool stack (yay, zsh/oh-my-zsh, tmux, neovim/lazyvim, python, node, AI tools) on the base Arch image
- `image-upload`: Per-provider scripts to upload the locally-built QCOW2 image to GCP, AWS, and Azure
- `vm-deploy`: Terraform configurations and cloud-init user-data for deploying and personalizing VMs from the custom image

### Modified Capabilities
None — this is a greenfield project.

## Impact

- **Dependencies**: Docker, QEMU/KVM (on the build host), Packer, Terraform, cloud provider CLIs (gcloud, aws, az)
- **Cloud resources**: Custom VM images stored per provider, VM instances
- **Host requirements**: Linux with KVM support for fast builds; macOS/Windows possible but slower without KVM acceleration
- **Security surface**: Provisioning scripts run as root during image build; cloud-init handles secrets injection at deploy time (secrets never baked into images)
