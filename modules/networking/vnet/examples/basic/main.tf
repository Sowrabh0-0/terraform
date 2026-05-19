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

module "vnet" {
  source = "../.."

  name                = "vnet-dev-hub-centralindia"
  address_space       = ["10.10.0.0/16"]
  location            = "centralindia"
  resource_group_name = "rg-dev-network-centralindia"

  tags = {
    environment = "dev"
    workload    = "network"
    managed_by  = "terraform"
  }
}
