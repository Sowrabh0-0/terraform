output "ids" {
  description = "Map of subnet names to subnet IDs."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "names" {
  description = "List of subnet names."
  value       = keys(azurerm_subnet.this)
}

output "address_prefixes" {
  description = "Map of subnet names to address prefixes."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.address_prefixes }
}