output "edge_public_ip" {
  description = "Point DuckDNS <name>.duckdns.org at this IP."
  value       = azurerm_public_ip.edge.ip_address
}

output "resource_group" {
  value = azurerm_resource_group.tutor.name
}

output "key_vault_name" {
  description = "Set the Tailscale auth key here: az keyvault secret set --vault-name <this> ..."
  value       = azurerm_key_vault.tutor.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.edge.name
}

output "edge_principal_id" {
  description = "Managed identity of the edge VM."
  value       = azurerm_linux_virtual_machine.edge.identity[0].principal_id
}
