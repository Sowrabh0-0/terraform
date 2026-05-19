mock_provider "azurerm" {}

run "plans_vnet" {
  command = plan

  variables {
    name                = "vnet-test-hub-centralindia"
    address_space       = ["10.10.0.0/16"]
    location            = "centralindia"
    resource_group_name = "rg-test-network-centralindia"
    dns_servers         = ["10.10.1.4", "10.10.1.5"]

    tags = {
      environment = "test"
      workload    = "network"
      managed_by  = "terraform"
    }
  }

  assert {
    condition     = azurerm_virtual_network.this.name == "vnet-test-hub-centralindia"
    error_message = "Expected the VNet name to match the input name."
  }

  assert {
    condition     = azurerm_virtual_network.this.location == "centralindia"
    error_message = "Expected the VNet location to match the input location."
  }

  assert {
    condition     = length(azurerm_virtual_network.this.address_space) == 1 && contains(azurerm_virtual_network.this.address_space, "10.10.0.0/16")
    error_message = "Expected the VNet address space to include 10.10.0.0/16."
  }

  assert {
    condition     = length(azurerm_virtual_network.this.dns_servers) == 2 && contains(azurerm_virtual_network.this.dns_servers, "10.10.1.4")
    error_message = "Expected the VNet DNS servers to include 10.10.1.4."
  }

  assert {
    condition     = azurerm_virtual_network.this.tags["environment"] == "test"
    error_message = "Expected tags to be applied to the VNet."
  }
}

run "plans_vnet_with_defaults" {
  command = plan

  variables {
    name                = "vnet-test-spoke-centralindia"
    address_space       = ["10.20.0.0/16"]
    location            = "centralindia"
    resource_group_name = "rg-test-network-centralindia"
  }

  assert {
    condition     = length(azurerm_virtual_network.this.dns_servers) == 0
    error_message = "Expected DNS servers to default to an empty list."
  }

  assert {
    condition     = length(azurerm_virtual_network.this.tags) == 0
    error_message = "Expected tags to default to an empty map."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    name                = "vnet-test-invalid-centralindia"
    address_space       = ["not-a-cidr"]
    location            = "centralindia"
    resource_group_name = "rg-test-network-centralindia"
  }

  expect_failures = [
    var.address_space
  ]
}
