# arch-dev-cloud

Reproducible Arch Linux development VM images, built locally with Docker + QEMU + Packer and deployable to GCP, AWS, or Azure.

## What's in the image

- **Shell**: zsh + oh-my-zsh (vi-mode plugin enabled) + tmux
- **Editor**: neovim + LazyVim
- **Languages**: Python 3 (pip, venv), Node.js 24 LTS (via nvm)
- **AI tools**: Claude Code, OpenCode
- **Package manager**: yay (AUR access)

## Prerequisites

- Linux host with Docker and KVM (`/dev/kvm`)
- Terraform (for deploying VMs)
- `qemu-img` (for image format conversion during upload)
- Cloud CLI for your provider: `gcloud`/`gsutil`, `aws`, or `az` (for uploading images and deploying)

KVM is required for fast builds (~5-10 min). Without it, QEMU falls back to software emulation which is significantly slower.

## Quick start

```bash
# 1. Build the image
make build

# 2. Configure upload settings
cp .env.example .env
# Edit .env with your GCP_PROJECT, GCS_BUCKET, etc.

# 3. Upload to your cloud provider
make upload-gcp    # or upload-aws, upload-az

# 4. Configure secrets
cp secrets.tfvars.example secrets.tfvars
# Edit secrets.tfvars with your SSH keys, API keys, git config, repos

# 5. Deploy a VM
make deploy-gcp    # or deploy-aws, deploy-az
```

## Project structure

```
build/
  Dockerfile          # Builder container (Arch + QEMU + Packer)
  build.sh            # Container entrypoint
packer/
  arch-dev.pkr.hcl    # Packer template (QEMU builder)
  scripts/
    01-base.sh        # System upgrade, base-devel, git, yay
    02-shell.sh       # zsh, oh-my-zsh, tmux
    03-editor.sh      # neovim, LazyVim
    04-languages.sh   # Python 3, nvm, Node.js 24
    05-ai-tools.sh    # Claude Code, OpenCode
    99-cleanup.sh     # Cache cleanup for smaller image
upload/
  upload-gcp.sh       # Convert to raw, upload to GCS, create GCP image
  upload-aws.sh       # Upload QCOW2 to AWS (via S3 staging)
  upload-az.sh        # Convert to VHD and upload to Azure
cloud-init/
  user-data.yaml.tpl  # Terraform-templated cloud-init config
terraform/
  gcp/                # GCP Compute Engine config
  aws/                # AWS EC2 config
  azure/              # Azure VM config
Makefile              # User-facing interface
.env.example          # Upload config template (GCP_PROJECT, GCS_BUCKET, etc.)
secrets.tfvars.example
```

## How it works

1. **Build**: A Docker container runs QEMU + Packer to boot the official [arch-boxes](https://gitlab.archlinux.org/archlinux/arch-boxes) cloud image and provision it with shell scripts. The output is a single QCOW2 file in `output/build/`. The build uses `-cpu host` to pass through host CPU features to the guest VM.

2. **Upload**: Provider-specific scripts convert and push the image to your cloud. For GCP, the QCOW2 is converted to raw format, packaged as a tar.gz, uploaded to a GCS bucket, and registered as a compute image. These run on the host using your existing cloud CLI credentials.

3. **Deploy**: Terraform creates a VM from the custom image. A cloud-init user-data template handles runtime personalization -- SSH keys, git config, API keys, and repo cloning. Cloud-init configures the existing `arch` user (which already has oh-my-zsh, zsh, and shell plugins from the build). Secrets are passed via a local `secrets.tfvars` file (gitignored) and never baked into the image.

## Secrets

Copy the example and fill in your values:

```bash
cp secrets.tfvars.example secrets.tfvars
```

The file expects:

| Variable | Description |
|---|---|
| `ssh_private_key` | SSH private key (for git over SSH) |
| `ssh_public_key` | SSH public key (for VM login) |
| `git_user_name` | Git `user.name` |
| `git_user_email` | Git `user.email` |
| `api_keys` | Map of env var names to API keys |
| `repos_to_clone` | List of git repo URLs to clone into `~/repos/` |

The `.tfvars` file is gitignored. Secrets are injected into the VM at boot via cloud-init, never stored in the image.

## Terraform variables

Each provider directory (`terraform/gcp/`, `terraform/aws/`, `terraform/azure/`) has a `variables.tf` with configurable defaults:

| Variable | GCP default | AWS default | Azure default |
|---|---|---|---|
| Region | `us-central1` | `us-east-1` | `eastus` |
| VM size | `e2-standard-2` | `t3.medium` | `Standard_D2s_v3` |
| Disk size | 50 GB | 50 GB | 50 GB |

Override in your `secrets.tfvars` or pass via `-var` flags.

## Upload configuration

Upload scripts load settings from a `.env` file in the project root:

```bash
cp .env.example .env
```

| Variable | Provider | Description |
|---|---|---|
| `GCP_PROJECT` | GCP | GCP project ID |
| `GCS_BUCKET` | GCP | GCS bucket for staging (e.g. `gs://my-bucket`) |

Provider-specific requirements:

- **GCP**: `gcloud`, `gsutil`, and `qemu-img`. The script converts QCOW2 to raw, uploads to GCS, and creates the image.
- **AWS**: `aws` CLI, authenticated. Set `AWS_IMAGE_BUCKET` env var to an S3 bucket for staging.
- **Azure**: `az` CLI + `qemu-img`, authenticated. Set `AZURE_RESOURCE_GROUP` env var.
