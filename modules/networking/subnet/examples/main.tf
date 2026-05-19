terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "subnets" {
  source = ".."

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
      address_prefixes = ["10.10.3.0/24"]
    }
  }
}
