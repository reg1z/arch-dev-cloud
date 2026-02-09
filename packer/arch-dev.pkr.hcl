packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "arch_image_url" {
  type    = string
  default = "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
}

variable "arch_image_checksum" {
  type    = string
  default = "none"
}

source "qemu" "arch-dev" {
  iso_url      = var.arch_image_url
  iso_checksum = var.arch_image_checksum
  disk_image   = true

  output_directory = "/output/build"
  vm_name          = "arch-dev.qcow2"

  format       = "qcow2"
  disk_size    = "10G"
  accelerator  = "kvm"
  machine_type = "q35"

  memory   = 4096
  cpus     = 2
  headless = true

  qemuargs = [
    ["-cpu", "host"],
  ]

  ssh_username = "arch"
  ssh_password = "arch"
  ssh_timeout  = "10m"

  shutdown_command = "sudo systemctl poweroff"

  cd_content = {
    "meta-data" = ""
    "user-data" = <<-EOF
      #cloud-config
      users:
        - name: arch
          plain_text_passwd: arch
          lock_passwd: false
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
      ssh_pwauth: true
    EOF
  }
  cd_label = "cidata"
}

build {
  sources = ["source.qemu.arch-dev"]

  provisioner "shell" {
    scripts = [
      "/packer/scripts/01-base.sh",
      "/packer/scripts/02-shell.sh",
      "/packer/scripts/03-editor.sh",
      "/packer/scripts/04-languages.sh",
      "/packer/scripts/05-ai-tools.sh",
      "/packer/scripts/99-cleanup.sh",
    ]
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
