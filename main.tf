provider "azurerm" {
  features {}
    skip_provider_registration = true
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
}

variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}
variable "location" {}

# Kimlik bilgilerini .tfvars dosyasından yükleme
terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}


# Resource group oluştur
resource "azurerm_resource_group" "example" {
  name     = "test-resources"
  location = var.location
}

# Virtual network tanımla
resource "azurerm_virtual_network" "example" {
  name                = "test-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Subnet tanımla
resource "azurerm_subnet" "example" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP oluştur
resource "azurerm_public_ip" "example" {
  name                = "test-publicip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

# Network Security Group (NSG) oluştur
resource "azurerm_network_security_group" "example" {
  name                = "test-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

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

# Network arayüzü (NIC) oluştur
resource "azurerm_network_interface" "example" {
  name                = "test-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

# Sanal makineyi oluştur
resource "azurerm_virtual_machine" "example" {
  name                  = "test-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "test-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 140 # Disk boyutunu burada belirtin
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "yecuser"
    admin_password = "Yecuser1!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
