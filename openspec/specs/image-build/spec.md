## Purpose

Defines how the Arch Linux dev VM image is built using Packer inside a Docker container.

## Requirements

### Requirement: Containerized build environment
The system SHALL provide a Dockerfile that produces a build container with QEMU, Packer, xorriso (for cloud-init CD ISO creation), and all build dependencies on an Arch Linux base. The container SHALL be the only dependency needed on the host besides Docker and KVM.

#### Scenario: Build the builder image
- **WHEN** the user runs `make build`
- **THEN** Docker builds the builder image containing QEMU, Packer, xorriso, and all build dependencies

#### Scenario: No host dependencies beyond Docker
- **WHEN** a user clones the repo on a Linux machine with Docker and KVM available
- **THEN** they can produce a VM image without installing QEMU, Packer, or any other tool on the host

### Requirement: Packer QEMU builder template
The system SHALL include a Packer template (`arch-dev.pkr.hcl`) that uses the QEMU builder with `disk_image = true` to boot the official arch-boxes cloud image. The template SHALL use `cd_content` to provide a cloud-init NoCloud seed for temporary SSH access during the build. The template SHALL pass `-cpu host` via `qemuargs` to expose the host CPU's instruction set to the guest VM.

#### Scenario: Packer boots the official Arch cloud image
- **WHEN** Packer executes inside the build container
- **THEN** it downloads the latest official Arch Linux cloud image from the arch-boxes mirror and boots it via QEMU

#### Scenario: Packer establishes SSH via cloud-init seed
- **WHEN** the QEMU VM boots with the cidata CD attached
- **THEN** cloud-init creates a temporary build user and enables password-based SSH so Packer can connect and run provisioners

#### Scenario: Host CPU passthrough
- **WHEN** QEMU starts the build VM
- **THEN** it uses `-cpu host` so the guest has access to the host's full CPU instruction set, avoiding illegal instruction crashes from tools like Bun/Claude Code that require modern CPU features

### Requirement: KVM acceleration passthrough
The build container SHALL be launched with `--device /dev/kvm` to pass through hardware virtualization from the host. The system SHALL function without KVM but MAY be significantly slower.

#### Scenario: Fast build with KVM
- **WHEN** the host has `/dev/kvm` available and the container is launched with `--device /dev/kvm`
- **THEN** QEMU uses KVM acceleration and the build completes in approximately 5-10 minutes

#### Scenario: Build without KVM
- **WHEN** the host does not have `/dev/kvm` available
- **THEN** QEMU falls back to software emulation and the build still completes, but takes significantly longer

### Requirement: QCOW2 output
The build SHALL produce a single QCOW2 image file in an `output/build/` subdirectory. The image SHALL have caches stripped (`pacman -Scc`, `npm cache clean`) to minimize file size. Packer's `output_directory` SHALL be set to a subdirectory of the volume mount to avoid conflicts with the pre-existing mount point.

#### Scenario: Image output location
- **WHEN** the build completes successfully
- **THEN** the provisioned QCOW2 image is available at `output/build/arch-dev.qcow2` on the host (via volume mount)

#### Scenario: Cache cleanup
- **WHEN** provisioning scripts have finished installing all packages
- **THEN** package manager and runtime caches are cleared before the image is finalized

#### Scenario: No output directory conflict
- **WHEN** Packer starts a build
- **THEN** it creates `output/build/` as its output directory, avoiding conflict with the Docker volume mount at `/output`

### Requirement: Makefile interface
The system SHALL provide a Makefile with a `build` target as the primary user-facing command for building images.

#### Scenario: Single command build
- **WHEN** the user runs `make build` from the project root
- **THEN** the system builds the Docker builder image (if needed), launches the container with KVM passthrough and volume mounts, runs Packer, and outputs the QCOW2 to `output/build/`
