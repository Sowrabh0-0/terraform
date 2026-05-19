resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  default_outbound_access_enabled   = each.value.default_outbound_access_enabled
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegations

    content {
      name = delegation.key

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}