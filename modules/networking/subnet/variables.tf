variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network where the subnets will be created."
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create."
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    default_outbound_access_enabled   = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Disabled")

    delegations = optional(map(object({
      service_name = string
      actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/join/action"])
    })), {})
  }))

  validation {
    condition = length(var.subnets) > 0 && alltrue(flatten([
      for subnet in values(var.subnets) : [
        for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))
      ]
    ]))
    error_message = "Each subnet must include at least one valid CIDR block in address_prefixes."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(
        ["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"],
        subnet.private_endpoint_network_policies
      )
    ])
    error_message = "private_endpoint_network_policies must be one of Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}
