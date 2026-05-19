# Azure Subnet Module

This Terraform module creates one or more Azure subnets inside an existing Azure Virtual Network.

## Purpose

Use this module when you want to create multiple subnets in a consistent way for an environment or network layer.

This module creates:

- One or more Azure subnets
- Optional service endpoints per subnet
- Optional subnet delegation per subnet
- Optional private endpoint network policy configuration
- Optional default outbound access control per subnet

This module does not create:

- Resource group
- Virtual network
- Network security groups
- Route tables
- NAT Gateway
- Subnet-to-NSG associations
- Subnet-to-route-table associations

Those should be created by separate modules or by a higher-level networking composition module.

## Usage

```hcl
module "subnets" {
  source = "../../../modules/networking/subnet"

  resource_group_name  = "rg-dev-network-centralindia"
  virtual_network_name = "vnet-dev-hub-centralindia"

  subnets = {
    app = {
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }

    db = {
      address_prefixes = ["10.10.2.0/24"]
    }

    private-endpoint = {
      address_prefixes                  = ["10.10.3.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
    }
  }
}
```

## Example With Multiple Service Endpoints

```hcl
module "subnets" {
  source = "../../../modules/networking/subnet"

  resource_group_name  = "rg-prod-network-centralindia"
  virtual_network_name = "vnet-prod-hub-centralindia"

  subnets = {
    app = {
      address_prefixes = ["10.20.1.0/24"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
    }

    aks = {
      address_prefixes = ["10.20.2.0/23"]
      service_endpoints = [
        "Microsoft.ContainerRegistry"
      ]
    }

    data = {
      address_prefixes = ["10.20.4.0/24"]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage"
      ]
    }
  }
}
```

## Example With Delegation

```hcl
module "subnets" {
  source = "../../../modules/networking/subnet"

  resource_group_name  = "rg-prod-network-centralindia"
  virtual_network_name = "vnet-prod-hub-centralindia"

  subnets = {
    postgres = {
      address_prefixes = ["10.20.5.0/24"]

      delegations = {
        postgres = {
          service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
    }
  }
}
```

## Requirements

| Name | Version |
| --- | --- |
| Terraform | `>= 1.5.0` |
| AzureRM | `~> 4.0` |

## Providers

| Name | Source |
| --- | --- |
| AzureRM | `hashicorp/azurerm` |

## Inputs

| Name | Description | Type | Required | Default |
| --- | --- | --- | --- | --- |
| `resource_group_name` | The name of the resource group that contains the virtual network. | `string` | Yes | N/A |
| `virtual_network_name` | The name of the virtual network where the subnets will be created. | `string` | Yes | N/A |
| `subnets` | Map of subnets to create. The map key is used as the subnet name. | `map(object)` | Yes | N/A |

### `subnets` Object

Each subnet object supports:

| Name | Description | Type | Required | Default |
| --- | --- | --- | --- | --- |
| `address_prefixes` | Address prefixes for the subnet in CIDR notation. | `list(string)` | Yes | N/A |
| `service_endpoints` | Optional service endpoints for the subnet. | `list(string)` | No | `[]` |
| `default_outbound_access_enabled` | Whether default outbound access to the internet is enabled for the subnet. Set to `false` for private subnets. | `bool` | No | `false` |
| `private_endpoint_network_policies` | Private endpoint network policy mode. | `string` | No | `Disabled` |
| `delegations` | Optional subnet delegations. | `map(object)` | No | `{}` |

## Outputs

| Name | Description |
| --- | --- |
| `ids` | Map of subnet names to subnet IDs. |
| `names` | List of subnet names. |
| `address_prefixes` | Map of subnet names to address prefixes. |

## Validation

Run these commands from this module directory:

```powershell
terraform init
terraform fmt -check
terraform validate
```

## Notes

- The virtual network must already exist before this module is applied.
- The resource group must already exist before this module is applied.
- The map key in `subnets` becomes the subnet name.
- If a subnet does not need service endpoints, omit `service_endpoints` or set it to `[]`.
- Set `default_outbound_access_enabled = false` for private subnets.
- Use `delegations` only for subnets that require a specific Azure service delegation.
- Network security group and route table associations are intentionally not managed by this module.
