terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "dev" {
  name     = "arch-dev-rg"
  location = var.location
}

resource "azurerm_virtual_network" "dev" {
  name                = "arch-dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
}

resource "azurerm_subnet" "dev" {
  name                 = "arch-dev-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "dev" {
  name                = "arch-dev-pip"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "dev" {
  name                = "arch-dev-nsg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "dev" {
  name                = "arch-dev-nic"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev.id
  }
}

resource "azurerm_network_interface_security_group_association" "dev" {
  network_interface_id      = azurerm_network_interface.dev.id
  network_security_group_id = azurerm_network_security_group.dev.id
}

resource "azurerm_linux_virtual_machine" "dev" {
  name                = "arch-dev"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  size                = var.vm_size
  admin_username      = var.username

  network_interface_ids = [
    azurerm_network_interface.dev.id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_id = var.image_id

  custom_data = base64encode(templatefile("${path.module}/../../cloud-init/user-data.yaml.tpl", {
    username        = var.username
    ssh_public_key  = var.ssh_public_key
    ssh_private_key = var.ssh_private_key
    git_user_name   = var.git_user_name
    git_user_email  = var.git_user_email
    api_keys        = var.api_keys
    repos_to_clone  = var.repos_to_clone
  }))
}
