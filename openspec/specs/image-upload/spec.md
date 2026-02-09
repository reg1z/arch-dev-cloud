## Purpose

Defines how built VM images are uploaded to cloud providers for deployment.

## Requirements

### Requirement: GCP image upload
The system SHALL provide a script (`upload/upload-gcp.sh`) that uploads the built image to Google Cloud Platform as a custom compute image. Because GCP does not support Arch Linux via `gcloud compute images import`, the script SHALL convert the QCOW2 to raw format, package it as a `disk.raw` inside a `.tar.gz`, upload it to a GCS bucket, and create the image with `gcloud compute images create`.

#### Scenario: Upload to GCP
- **WHEN** the user runs `make upload-gcp` (or `./upload/upload-gcp.sh` directly)
- **THEN** the QCOW2 is converted to raw, compressed as tar.gz, uploaded to GCS, and registered as a GCP compute image with a date-stamped name

#### Scenario: GCP CLI and tools required
- **WHEN** the user attempts to upload to GCP without `gcloud`, `gsutil`, or `qemu-img` installed
- **THEN** the script fails with a clear error message identifying the missing tool

#### Scenario: GCP project and bucket configuration
- **WHEN** the user runs the GCP upload script
- **THEN** the script reads `GCP_PROJECT` and `GCS_BUCKET` from the `.env` file (or environment), and the `--project` flag is passed to `gcloud compute images create`

### Requirement: AWS image upload
The system SHALL provide a script (`upload/upload-aws.sh`) that uploads the built QCOW2 image to AWS as an AMI using `aws ec2 import-image`.

#### Scenario: Upload to AWS
- **WHEN** the user runs `make upload-aws` (or `./upload/upload-aws.sh` directly)
- **THEN** the QCOW2 from `output/build/` is uploaded to AWS and an AMI is created

#### Scenario: AWS CLI required
- **WHEN** the user attempts to upload to AWS without `aws` CLI installed and authenticated
- **THEN** the script fails with a clear error message

### Requirement: Azure image upload
The system SHALL provide a script (`upload/upload-az.sh`) that uploads the built image to Azure. The script SHALL convert the QCOW2 to VHD format (via `qemu-img convert`) before uploading, since Azure requires VHD.

#### Scenario: Upload to Azure with format conversion
- **WHEN** the user runs `make upload-az` (or `./upload/upload-az.sh` directly)
- **THEN** the QCOW2 is converted to VHD format and uploaded to Azure as a custom image

#### Scenario: Azure CLI required
- **WHEN** the user attempts to upload to Azure without `az` CLI installed and authenticated
- **THEN** the script fails with a clear error message

### Requirement: Environment file configuration
Upload scripts SHALL source a `.env` file from the project root (if present) to load configuration variables such as `GCP_PROJECT` and `GCS_BUCKET`. A `.env.example` file SHALL exist with placeholder values. The `.env` file SHALL be gitignored.

#### Scenario: Configuration via .env
- **WHEN** the user creates a `.env` file from `.env.example` and fills in values
- **THEN** upload scripts automatically load those values without requiring manual environment variable exports

#### Scenario: .env not in version control
- **WHEN** the project is cloned
- **THEN** `.gitignore` prevents `.env` from being committed

### Requirement: Makefile upload targets
The Makefile SHALL provide `upload-gcp`, `upload-aws`, and `upload-az` targets that invoke the corresponding upload scripts.

#### Scenario: Upload via Makefile
- **WHEN** the user runs `make upload-gcp`, `make upload-aws`, or `make upload-az`
- **THEN** the corresponding upload script executes

### Requirement: Upload scripts run on the host
All upload scripts SHALL run directly on the host machine (not inside a container). They SHALL require the user to have the relevant cloud CLI installed and authenticated.

#### Scenario: No containerization for uploads
- **WHEN** the user runs an upload script
- **THEN** it executes using the host's cloud CLI and credentials directly
