output "storage_account_name" {
  description = "Storage Accout Name"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_container_blob_name" {
  description = "Container Blob Name"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  value = <<EOT
        backend "azurerm" {
            resource_group_name  = "${azurerm_resource_group.tfstate.name}"
            storage_account_name = "${azurerm_storage_account.tfstate.name}"
            container_name       = "${azurerm_storage_container.tfstate.name}"
            key                  = "terraform.tfstate"
  }
    EOT
}

output "storage_account_access_key" {
  description = "Storage account primary key"
  value       = azurerm_storage_account.tfstate.primary_access_key
  sensitive   = true
}