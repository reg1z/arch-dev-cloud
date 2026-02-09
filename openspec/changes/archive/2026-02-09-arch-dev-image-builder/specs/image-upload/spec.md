## ADDED Requirements

### Requirement: GCP image upload
The system SHALL provide a script (`upload/upload-gcp.sh`) that uploads the built QCOW2 image to Google Cloud Platform as a custom compute image using `gcloud compute images import`.

#### Scenario: Upload to GCP
- **WHEN** the user runs `make upload-gcp` (or `./upload/upload-gcp.sh` directly)
- **THEN** the QCOW2 from `output/` is uploaded to GCP as a custom image with a date-stamped name

#### Scenario: GCP CLI required
- **WHEN** the user attempts to upload to GCP without `gcloud` installed and authenticated
- **THEN** the script fails with a clear error message

### Requirement: AWS image upload
The system SHALL provide a script (`upload/upload-aws.sh`) that uploads the built QCOW2 image to AWS as an AMI using `aws ec2 import-image`.

#### Scenario: Upload to AWS
- **WHEN** the user runs `make upload-aws` (or `./upload/upload-aws.sh` directly)
- **THEN** the QCOW2 from `output/` is uploaded to AWS and an AMI is created

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
