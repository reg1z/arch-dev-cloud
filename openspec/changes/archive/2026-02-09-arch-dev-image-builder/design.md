## Context

This is a greenfield project. There is no existing infrastructure or automation — just a manual runbook (`project-description.md`) listing the desired tools and configuration steps for an Arch Linux development VM.

The target is a persistent cloud VM that a developer SSHs into daily. The system should be templateable so others can fork and customize it.

The official Arch Linux cloud image from the [arch-boxes project](https://gitlab.archlinux.org/archlinux/arch-boxes) serves as the base. It's a QCOW2 image with cloud-init pre-installed, built on btrfs+zstd, with systemd-networkd and sshd enabled. It ships with no user accounts — cloud-init handles user creation at boot time.

## Goals / Non-Goals

**Goals:**
- Build a fully provisioned Arch Linux dev VM image locally without cloud credentials
- Containerize the build environment so any Linux machine with Docker can produce the image
- Support uploading the built image to GCP, AWS, and Azure
- Deploy a VM from the image with runtime personalization (SSH keys, secrets, repos) via Terraform + cloud-init
- Keep the user-facing interface simple: `make build`, `make upload-gcp`, `make deploy-gcp`

**Non-Goals:**
- Auto-updating the running VM after initial deploy (run Packer again and redeploy instead)
- Supporting non-Arch base images
- Container-based dev environments (this is explicitly a VM)
- CI/CD pipeline for automated image builds (may be added later but not in initial scope)
- Managing multiple simultaneous VMs or team-wide fleet management

## Decisions

### 1. Local QEMU build over cloud-native Packer builders

**Decision**: Use Packer's QEMU builder to build images locally inside a Docker container.

**Alternatives considered**:
- *Cloud-native builders* (`googlecompute`, `amazon-ebs`): Would require cloud credentials during build, pay for compute, and produce one image per cloud. Rebuild needed per provider.
- *Manual snapshots*: Not reproducible, not versionable.

**Rationale**: Local builds are free, need no cloud credentials, produce a single QCOW2 that can be uploaded to any provider, and can be tested locally before uploading. The tradeoff is requiring KVM on the build host for acceptable performance (~5-10 min with KVM vs hours without).

### 2. Docker container as the build environment

**Decision**: Wrap QEMU + Packer in a Docker container so the host only needs Docker installed.

**Rationale**: Eliminates "install QEMU and Packer on your machine" as a prerequisite. Makes the build reproducible regardless of host Packer/QEMU versions. The container uses an Arch Linux base image so tooling matches the target.

**KVM passthrough**: The container runs with `--device /dev/kvm` on Linux for hardware acceleration. On macOS/Windows, builds work but are significantly slower — this is an accepted tradeoff since the primary audience uses Linux.

### 3. Official arch-boxes cloud image as base

**Decision**: Use the official Arch Linux cloud image from arch-boxes, not community AMIs or custom bootstraps.

**Alternatives considered**:
- *Community cloud images* (per-provider): Less trustworthy, inconsistent across providers.
- *Bootstrap via pacstrap*: Full control but significantly more work to maintain.

**Rationale**: Official, PGP-signed, updated fortnightly. Ships with cloud-init, btrfs root, and a minimal base. Packer boots this QCOW2 directly via `disk_image = true`.

### 4. cloud-init NoCloud seed for Packer SSH access

**Decision**: Use Packer's `cd_content` to create a virtual cidata CD with a cloud-init NoCloud configuration, setting up a temporary build user with password auth.

**Rationale**: The arch-boxes cloud image has no default user — cloud-init creates users on boot. For the Packer build, we need SSH access, so we provide a minimal cloud-init config that creates a temporary `arch` user with a password. This user and password only exist during the build process and are not present in the final image (cloud-init re-runs on actual deployment with real credentials).

### 5. Ordered shell scripts as provisioners

**Decision**: Use numbered shell scripts (`01-base.sh` through `05-ai-tools.sh`) run as Packer shell provisioners.

**Alternatives considered**:
- *Ansible provisioner*: More idempotent, but adds complexity and another tool to learn. Overkill for a sequential install-and-configure flow.
- *Single monolithic script*: Harder to debug, can't re-run individual stages.

**Rationale**: Shell scripts are transparent, debuggable, and match the mental model of "SSH in and run commands." Numbered ordering makes the dependency chain explicit. Each script is independently testable.

### 6. Separate upload scripts per provider

**Decision**: Simple shell scripts (`upload-gcp.sh`, `upload-aws.sh`, `upload-az.sh`) that wrap the respective cloud CLI import commands. Run from the host, not from a container.

**Alternatives considered**:
- *Containerized upload with cloud CLIs*: More portable but makes credential handling fiddly (mounting auth tokens/configs into the container).
- *Packer post-processors*: Packer's QEMU builder doesn't have built-in post-processors for cloud upload.

**Rationale**: Upload scripts are ~5-10 lines each. Users already have cloud CLIs installed and authenticated for Terraform. No reason to add complexity.

### 7. Terraform for VM deployment, cloud-init for runtime config

**Decision**: Use Terraform with per-provider configurations to deploy VMs. Pass a cloud-init user-data YAML for runtime personalization.

**Rationale**: Terraform handles the declarative infrastructure (VM size, disk, networking, firewall rules). cloud-init handles what can't be baked into the image: SSH public key injection, git config, cloning repos, fetching secrets from the provider's secret manager. This separation keeps secrets out of the image.

### 8. Secrets via Terraform variables

**Decision**: Secrets (SSH private key, API keys) are stored in a local `.tfvars` file (gitignored) and injected into cloud-init user-data via Terraform variable interpolation.

**Alternatives considered**:
- *Cloud-native secret managers* (GCP Secret Manager, AWS Secrets Manager, Azure Key Vault): Powerful but ties secrets management to a specific cloud provider, adding complexity for a single-user setup.
- *sops/age encrypted files in repo*: Cloud-agnostic but requires managing an age key and installing sops tooling.
- *HashiCorp Vault*: Heavy infrastructure for a single-user dev setup.
- *Password manager CLI* (1Password, Bitwarden): Requires a specific provider account and service token.

**Rationale**: The simplest fully cloud-agnostic option. The user creates a `secrets.tfvars` file locally with their SSH key, API keys, etc. Terraform interpolates these into the cloud-init user-data template. No extra tools, no cloud-specific APIs, no accounts. The `.tfvars` file is gitignored so secrets never enter version control. Other users forking the template simply create their own `.tfvars` file.

## Risks / Trade-offs

- **KVM required for fast builds** → Document this clearly. Provide estimated build times with and without KVM. macOS/Windows users can use a Linux VM with KVM for builds.
- **Arch rolling release may break provisioning scripts** → Pin package versions where critical. Run builds periodically to catch breakage early. The arch-boxes base image is updated fortnightly.
- **QCOW2 format needs conversion for some providers** → GCP accepts QCOW2 directly. AWS accepts QCOW2 via `import-image`. Azure needs VHD conversion (qemu-img can do this in the upload script).
- **Large image size** → A fully provisioned image could be several GB. Uploading takes time on slow connections. Consider stripping caches (`pacman -Scc`, `npm cache clean`) at the end of the build.
- **cloud-init runs once** → If cloud-init fails or needs re-running, you may need to redeploy. For a persistent dev VM, this is acceptable — the initial setup either works or you fix the user-data and redeploy.

## Resolved Questions

- **Disk size**: The image ships at minimal size. The deploy-time disk is sized via Terraform (user-configurable). cloud-init runs `growpart` + `btrfs filesystem resize` on first boot to expand the root filesystem to fill the allocated disk.
- **Shell config**: oh-my-zsh baked into the image with its built-in [vi-mode](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/vi-mode/README.md) plugin enabled.
- **neovim config**: LazyVim starter config baked into the image.
- **SAST/DAST tools**: sonarqube and semgrep removed from scope — too heavy and not core to the dev environment. Can be added by users post-deploy if needed.
