provider "azurerm" {
features {}
}
terraform {
  required_version = "= 0.11.15"
}


variable "vm_size" {}
variable "username" {}
variable "password" {}

variable "name" {
  default = "terrauser"
}

variable "location" {
  default = "eastus"
}

variable "vmcount" {
  default = 0
  # default = 2
}

# Basic Resources
resource "azurerm_resource_group" "main" {
  name     = "${var.name}-rg"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "main" {
  name                 = "${var.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefixes      = "10.0.1.0/24"
}

# VM Resources
resource "azurerm_public_ip" "main" {
  name                = "${var.name}-pubip${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
  count               = "${var.vmcount}"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.name}-nic${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  count               = "${var.vmcount}"

  ip_configuration {
    name                          = "config1"
    subnet_id                     = "${azurerm_subnet.main.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.main.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.name}-vm${count.index}"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${element(azurerm_network_interface.main.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  count                 = "${var.vmcount}"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.name}vm${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.name}vm${count.index}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_windows_config {}
}

## Outputs
output "private-ip" {
  value       = "${azurerm_network_interface.main.*.private_ip_address}"
  description = "Private IP Address"
}

output "public-ip" {
  value       = "${azurerm_public_ip.main.*.ip_address}"
  description = "Public IP Address"
}
