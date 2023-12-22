resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = "demo-tfstate-rg"
  location = "Central US"
  tags = {
    Application = "Terraform"
    Purpose     = "RemoteState"
    Type        = "ResourceGroup"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_string.resource_code.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Application = "Terraform"
    Purpose     = "RemoteState"
    Type        = "StorageAccount"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate-container"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}