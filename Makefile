BUILDER_IMAGE := arch-dev-builder
OUTPUT_DIR := $(CURDIR)/output

.PHONY: build upload-gcp upload-aws upload-az deploy-gcp deploy-aws deploy-az

build:
	docker build -t $(BUILDER_IMAGE) build/
	mkdir -p $(OUTPUT_DIR)
	docker run --rm \
		--device /dev/kvm \
		-v $(CURDIR)/packer:/packer:ro \
		-v $(OUTPUT_DIR):/output \
		$(BUILDER_IMAGE)

upload-gcp:
	./upload/upload-gcp.sh

upload-aws:
	./upload/upload-aws.sh

upload-az:
	./upload/upload-az.sh

deploy-gcp:
	cd terraform/gcp && terraform init && terraform apply -var-file="../../secrets.tfvars"

deploy-aws:
	cd terraform/aws && terraform init && terraform apply -var-file="../../secrets.tfvars"

deploy-az:
	cd terraform/azure && terraform init && terraform apply -var-file="../../secrets.tfvars"
