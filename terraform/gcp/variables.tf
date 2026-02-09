variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "image_name" {
  description = "Name of the custom Arch dev image"
  type        = string
}

variable "username" {
  description = "Username to create on the VM"
  type        = string
  default     = "arch"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "SSH private key to place on the VM"
  type        = string
  sensitive   = true
}

variable "git_user_name" {
  description = "Git user.name"
  type        = string
  sensitive   = true
}

variable "git_user_email" {
  description = "Git user.email"
  type        = string
  sensitive   = true
}

variable "api_keys" {
  description = "Map of API key environment variable names to values"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "repos_to_clone" {
  description = "List of git repository URLs to clone"
  type        = list(string)
  default     = []
  sensitive   = true
}
