mock_provider "azurerm" {}

run "plans_multiple_subnets" {
  command = plan

  variables {
    resource_group_name  = "rg-test-network-centralindia"
    virtual_network_name = "vnet-test-hub-centralindia"

    subnets = {
      app = {
        address_prefixes  = ["10.10.1.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }

      private_endpoint = {
        address_prefixes                  = ["10.10.2.0/24"]
        default_outbound_access_enabled   = false
        private_endpoint_network_policies = "Disabled"
      }

      postgres = {
        address_prefixes = ["10.10.3.0/24"]

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

  assert {
    condition     = length(azurerm_subnet.this) == 3
    error_message = "Expected three subnets to be planned."
  }

  assert {
    condition     = azurerm_subnet.this["app"].name == "app"
    error_message = "Expected the app subnet name to come from the subnets map key."
  }

  assert {
    condition     = length(azurerm_subnet.this["app"].service_endpoints) == 1 && contains(azurerm_subnet.this["app"].service_endpoints, "Microsoft.Storage")
    error_message = "Expected service endpoints to be configured for the app subnet."
  }

  assert {
    condition     = azurerm_subnet.this["private_endpoint"].default_outbound_access_enabled == false
    error_message = "Expected private_endpoint subnet default outbound access to be disabled."
  }

  assert {
    condition     = azurerm_subnet.this["private_endpoint"].private_endpoint_network_policies == "Disabled"
    error_message = "Expected private endpoint network policies to be disabled."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    resource_group_name  = "rg-test-network-centralindia"
    virtual_network_name = "vnet-test-hub-centralindia"

    subnets = {
      invalid = {
        address_prefixes = ["not-a-cidr"]
      }
    }
  }

  expect_failures = [
    var.subnets
  ]
}
