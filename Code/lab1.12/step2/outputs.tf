output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "linux_public_ip_address" {
  value = azurerm_linux_virtual_machine.demo_terraform_vm.public_ip_address
}

output "windows_public_ip_address" {
  value = azurerm_windows_virtual_machine.demo_windows_vm.public_ip_address
}