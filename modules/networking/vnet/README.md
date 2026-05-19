# Azure Virtual Network Module

This Terraform module creates an Azure Virtual Network.

## Purpose

Use this module when you need a reusable and consistent way to create VNets across environments such as `dev`, `staging`, and `prod`.

This module creates:

- Azure Virtual Network
- Optional custom DNS server configuration
- Tags on the virtual network

This module does not create:

- Resource group
- Subnets
- Network security groups
- Route tables
- NAT Gateway
- Firewall

Those should be created by separate modules or by a higher-level networking composition module.

## Usage

```hcl
module "vnet" {
  source = "../../../modules/networking/vnet"

  name                = "vnet-dev-hub-centralindia"
  address_space       = ["10.10.0.0/16"]
  location            = "centralindia"
  resource_group_name = "rg-dev-network-centralindia"

  dns_servers = []

  tags = {
    environment = "dev"
    workload    = "network"
    managed_by  = "terraform"
  }
}
```

## Example With Custom DNS Servers

```hcl
module "vnet" {
  source = "../../../modules/networking/vnet"

  name                = "vnet-prod-hub-centralindia"
  address_space       = ["10.20.0.0/16"]
  location            = "centralindia"
  resource_group_name = "rg-prod-network-centralindia"

  dns_servers = [
    "10.20.1.4",
    "10.20.1.5"
  ]

  tags = {
    environment = "prod"
    workload    = "network"
    managed_by  = "terraform"
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
| `name` | The name of the virtual network. | `string` | Yes | N/A |
| `address_space` | The address space of the virtual network. Must contain at least one valid CIDR block. | `list(string)` | Yes | N/A |
| `location` | The Azure region where the virtual network will be created. | `string` | Yes | N/A |
| `resource_group_name` | The name of the resource group where the virtual network will be created. | `string` | Yes | N/A |
| `dns_servers` | Optional list of DNS servers for the virtual network. | `list(string)` | No | `[]` |
| `tags` | Tags to apply to the virtual network. | `map(string)` | No | `{}` |

## Outputs

| Name | Description |
| --- | --- |
| `id` | The ID of the virtual network. |
| `name` | The name of the virtual network. |
| `address_space` | The address space of the virtual network. |
| `resource_group_name` | The resource group name of the virtual network. |

## Validation

Run these commands from this module directory:

```powershell
terraform init
terraform fmt -check
terraform validate
```

## Notes

- The AzureRM provider configuration should be defined in the root module, not inside this reusable child module.
- The resource group must already exist before this module is applied.
- Subnets are intentionally not included in this module. Add them through a separate subnet module or a higher-level networking module if required.
