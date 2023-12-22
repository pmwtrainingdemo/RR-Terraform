	output "ip_address" {
	value = azurerm_container_group.basics.ip_address
	}
	
	output "fqdn" {
	value = "http://${azurerm_container_group.basics.fqdn}"
	}
