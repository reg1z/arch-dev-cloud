## Purpose

Defines how VMs are deployed from the built image using Terraform and personalized via cloud-init.

## Requirements

### Requirement: Terraform configurations per provider
The system SHALL provide Terraform configurations for GCP, AWS, and Azure that deploy a VM from the custom-built image. Each configuration SHALL be in its own directory (`terraform/gcp/`, `terraform/aws/`, `terraform/azure/`).

#### Scenario: Deploy to GCP
- **WHEN** the user runs `make deploy-gcp` (or `terraform apply` in `terraform/gcp/`)
- **THEN** a GCP Compute Engine VM is created from the custom Arch image with the specified machine type, disk size, and networking

#### Scenario: Deploy to AWS
- **WHEN** the user runs `make deploy-aws` (or `terraform apply` in `terraform/aws/`)
- **THEN** an AWS EC2 instance is created from the custom AMI with the specified instance type, disk size, and security group

#### Scenario: Deploy to Azure
- **WHEN** the user runs `make deploy-az` (or `terraform apply` in `terraform/azure/`)
- **THEN** an Azure VM is created from the custom image with the specified VM size, disk size, and networking

### Requirement: Configurable VM parameters
Each Terraform configuration SHALL expose variables for VM size, disk size, region, and the custom image name/ID. These SHALL have sensible defaults but be overridable.

#### Scenario: Override VM size
- **WHEN** the user sets a variable for VM size (e.g., `machine_type = "e2-standard-4"`)
- **THEN** the deployed VM uses the specified size instead of the default

#### Scenario: Override disk size
- **WHEN** the user sets a variable for disk size (e.g., `disk_size_gb = 50`)
- **THEN** the deployed VM has a root disk of the specified size

### Requirement: Secrets via Terraform variables
The Terraform configurations SHALL accept sensitive values (SSH private key, LLM API keys) as variables marked `sensitive = true`. Users SHALL provide these via a gitignored `secrets.tfvars` file. The values SHALL be interpolated into the cloud-init user-data template.

#### Scenario: Secrets from .tfvars
- **WHEN** the user creates a `secrets.tfvars` file with `ssh_private_key` and `api_keys` variables and runs `terraform apply -var-file="secrets.tfvars"`
- **THEN** those secrets are injected into the cloud-init user-data and delivered to the VM at boot

#### Scenario: Secrets never in version control
- **WHEN** the project is cloned
- **THEN** a `.gitignore` entry prevents `*.tfvars` files (or specifically `secrets.tfvars`) from being committed

#### Scenario: Template for secrets
- **WHEN** a new user wants to set up their secrets
- **THEN** a `secrets.tfvars.example` file exists showing the required variable names with placeholder values

### Requirement: cloud-init runtime personalization
Each Terraform configuration SHALL pass a cloud-init user-data YAML to the VM. The user-data SHALL configure the existing `arch` user (created during the Packer build) with: SSH public key authorization, git `user.name` and `user.email`, SSH private key placement and ssh-agent setup, LLM API key placement, and repo cloning to `~/repos`. The default username SHALL be `arch` to match the user configured during the Packer image build, ensuring oh-my-zsh and shell configuration are preserved.

#### Scenario: SSH key injection
- **WHEN** the VM boots with cloud-init user-data
- **THEN** the specified SSH public key is authorized for login and the SSH private key is placed at `~/.ssh/` with correct permissions (600)

#### Scenario: Git configuration
- **WHEN** cloud-init completes
- **THEN** `git config --global user.name` and `git config --global user.email` are set to the values provided in the Terraform variables

#### Scenario: Repository cloning
- **WHEN** cloud-init completes
- **THEN** the repositories specified in the Terraform variables are cloned to `~/repos/`

#### Scenario: ssh-agent configuration
- **WHEN** the user logs in via SSH after cloud-init has run
- **THEN** the ssh-agent starts automatically and the SSH private key is added, enabling Git operations over SSH

#### Scenario: Username matches Packer image
- **WHEN** the VM is deployed with default settings
- **THEN** cloud-init configures the `arch` user, which already has oh-my-zsh, zsh, and shell plugins set up from the Packer build

### Requirement: Disk expansion on first boot
cloud-init SHALL expand the root partition and btrfs filesystem to fill the entire disk allocated by Terraform.

#### Scenario: Filesystem grows to fill disk
- **WHEN** Terraform allocates a 50GB disk but the image is only a few GB
- **THEN** cloud-init runs `growpart` and `btrfs filesystem resize` so the root filesystem uses the full 50GB

### Requirement: Makefile deploy targets
The Makefile SHALL provide `deploy-gcp`, `deploy-aws`, and `deploy-az` targets that run `terraform apply` in the corresponding directory.

#### Scenario: Deploy via Makefile
- **WHEN** the user runs `make deploy-gcp`
- **THEN** `terraform apply` is executed in `terraform/gcp/` with the appropriate variable files

### Requirement: Firewall and networking
Each Terraform configuration SHALL configure networking to allow SSH access (port 22) to the VM. All other ports SHALL be closed by default.

#### Scenario: SSH access only
- **WHEN** the VM is deployed
- **THEN** port 22 is open for SSH and no other inbound ports are open by default
