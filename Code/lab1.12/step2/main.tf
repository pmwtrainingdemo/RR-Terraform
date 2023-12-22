resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "demo_virtual_network" {
  name                = "demoVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "demo_vnet_subnet" {
  name                 = "demoSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.demo_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "demo_vnet_linux_public_ip" {
  name                = "demoLinuxPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create public IPs
resource "azurerm_public_ip" "demo_vnet_win_public_ip" {
  name                = "demoWinPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "demo_vnet_nsg" {
  name                = "demoNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985-5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "LinuxNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "linux_nic_config"
    subnet_id                     = azurerm_subnet.demo_vnet_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_vnet_linux_public_ip.id
  }
}

# Create network interface
resource "azurerm_network_interface" "win_vm_nic" {
  name                = "WinNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "win_nic_config"
    subnet_id                     = azurerm_subnet.demo_vnet_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_vnet_win_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "linux" {
  network_interface_id      = azurerm_network_interface.linux_vm_nic.id
  network_security_group_id = azurerm_network_security_group.demo_vnet_nsg.id
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "windows" {
  network_interface_id      = azurerm_network_interface.win_vm_nic.id
  network_security_group_id = azurerm_network_security_group.demo_vnet_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "demo_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "demo_terraform_vm" {
  name                  = "linuxVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.linux_vm_nic.id]
  size                  = "Standard_DS1_v2"

  tags = {
    Environment = "Dev"
    Owner       = "Alim"
    Team        = "FTDO"
    OS          = "Linux"
    Application = "Terraform"
    Purpose     = "Ansible"
    Type        = "VirtualMachine"
  }

  os_disk {
    name                 = "demoOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "linuxvm"
  admin_username                  = "demouser"
  admin_password                  = "demouser@123"
  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.demo_storage_account.primary_blob_endpoint
  }
}

resource "azurerm_windows_virtual_machine" "demo_windows_vm" {
  name                  = "windowsVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.win_vm_nic.id]

  tags = {
    Environment = "Dev"
    Owner       = "Alim"
    Team        = "FTDO"
    OS          = "Windows"
    Application = "Terraform"
    Purpose     = "Ansible"
    Type        = "VirtualMachine"
  }

  os_disk {
    name                 = "WinOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "windowsvm"
  admin_username = "demouser"
  admin_password = "demouser@123"

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.demo_storage_account.primary_blob_endpoint
  }
}
