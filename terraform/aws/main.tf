terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "dev_ssh" {
  name        = "arch-dev-ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev" {
  ami           = var.ami_id
  instance_type = var.instance_type

  root_block_device {
    volume_size = var.disk_size_gb
    volume_type = "gp3"
  }

  vpc_security_group_ids = [aws_security_group.dev_ssh.id]

  user_data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tpl", {
    username        = var.username
    ssh_public_key  = var.ssh_public_key
    ssh_private_key = var.ssh_private_key
    git_user_name   = var.git_user_name
    git_user_email  = var.git_user_email
    api_keys        = var.api_keys
    repos_to_clone  = var.repos_to_clone
  })
}
