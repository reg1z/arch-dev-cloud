## 1. Project scaffolding

- [x] 1.1 Create directory structure: `build/`, `packer/scripts/`, `upload/`, `terraform/gcp/`, `terraform/aws/`, `terraform/azure/`, `cloud-init/`
- [x] 1.2 Create `.gitignore` with entries for `output/`, `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, `.terraform/`
- [x] 1.3 Create `secrets.tfvars.example` with placeholder values for `ssh_private_key`, `ssh_public_key`, `git_user_name`, `git_user_email`, `api_keys`, `repos_to_clone`

## 2. Build environment (image-build)

- [x] 2.1 Create `build/Dockerfile` — Arch Linux base with `qemu-base`, `qemu-img`, `edk2-ovmf`, `curl`, `unzip`, and Packer binary installed
- [x] 2.2 Create `build/build.sh` — entrypoint script that initializes Packer plugins and runs `packer build`
- [x] 2.3 Create `packer/arch-dev.pkr.hcl` — Packer template with QEMU builder, `disk_image = true`, official arch-boxes cloud image URL, `cd_content` cloud-init NoCloud seed for temporary build user, and shell provisioner blocks for scripts `01` through `05`

## 3. Provisioning scripts

- [x] 3.1 Create `packer/scripts/01-base.sh` — `pacman -Syu`, install `base-devel` and `git`, create non-root build user, install `yay` from AUR
- [x] 3.2 Create `packer/scripts/02-shell.sh` — install `zsh` and `tmux`, install oh-my-zsh, configure `.zshrc` with `plugins=(vi-mode)`, set zsh as default shell
- [x] 3.3 Create `packer/scripts/03-editor.sh` — install `neovim`, clone LazyVim starter config to `~/.config/nvim/`, trigger plugin installation
- [x] 3.4 Create `packer/scripts/04-languages.sh` — install `python`, `python-pip`, `python-virtualenv`; install nvm, install Node.js 24 LTS via nvm
- [x] 3.5 Create `packer/scripts/05-ai-tools.sh` — install Claude Code via official install script, install OpenCode via official install script
- [x] 3.6 Create `packer/scripts/99-cleanup.sh` — run `pacman -Scc --noconfirm`, `npm cache clean --force`, clear any other caches to minimize image size

## 4. Upload scripts (image-upload)

- [x] 4.1 Create `upload/upload-gcp.sh` — check for `gcloud` CLI, upload QCOW2 via `gcloud compute images import` with date-stamped name
- [x] 4.2 Create `upload/upload-aws.sh` — check for `aws` CLI, upload QCOW2 via `aws ec2 import-image` with S3 staging
- [x] 4.3 Create `upload/upload-az.sh` — check for `az` CLI, convert QCOW2 to VHD via `qemu-img convert`, upload to Azure

## 5. Cloud-init user-data template

- [x] 5.1 Create `cloud-init/user-data.yaml.tpl` — Terraform-templated cloud-init config: user creation with SSH public key, write SSH private key to `~/.ssh/` with mode 600, write API keys, configure git user.name and user.email, clone repos to `~/repos/`, add ssh-agent auto-start to `.zshrc`, run `growpart` and `btrfs filesystem resize` for disk expansion

## 6. Terraform — GCP

- [x] 6.1 Create `terraform/gcp/main.tf` — provider config, compute instance resource using custom image, boot disk with configurable size, network interface, firewall rule for SSH (port 22 only), cloud-init user-data via metadata
- [x] 6.2 Create `terraform/gcp/variables.tf` — variables for project ID, region, zone, machine type, disk size, image name, plus sensitive variables for secrets (SSH keys, API keys, git config, repos)
- [x] 6.3 Create `terraform/gcp/outputs.tf` — output the VM's external IP address

## 7. Terraform — AWS

- [x] 7.1 Create `terraform/aws/main.tf` — provider config, EC2 instance resource using custom AMI, root volume with configurable size, security group for SSH (port 22 only), cloud-init user-data
- [x] 7.2 Create `terraform/aws/variables.tf` — variables for region, instance type, disk size, AMI ID, plus sensitive variables for secrets
- [x] 7.3 Create `terraform/aws/outputs.tf` — output the instance's public IP address

## 8. Terraform — Azure

- [x] 8.1 Create `terraform/azure/main.tf` — provider config, VM resource using custom image, OS disk with configurable size, network security group for SSH (port 22 only), cloud-init user-data
- [x] 8.2 Create `terraform/azure/variables.tf` — variables for location, VM size, disk size, image ID, plus sensitive variables for secrets
- [x] 8.3 Create `terraform/azure/outputs.tf` — output the VM's public IP address

## 9. Makefile

- [x] 9.1 Create `Makefile` with targets: `build` (docker build + docker run with KVM passthrough and volume mounts), `upload-gcp`, `upload-aws`, `upload-az`, `deploy-gcp`, `deploy-aws`, `deploy-az`
