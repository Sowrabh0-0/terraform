# Terraform Module Structure - Production Best Practices Guide

## Overview

This repository structure is designed for:

- Reusability
- Scalability
- Environment isolation
- Team collaboration
- Safer infrastructure changes
- Easier maintenance
- Enterprise-grade Infrastructure as Code (IaC)

The structure follows real-world production Terraform architecture patterns used by:

- Platform Engineering teams
- DevOps teams
- Cloud Infrastructure teams
- Kubernetes platforms
- Enterprise cloud deployments

## High-Level Structure

```text
terraform/
|-- modules/
|-- environments/
|-- global/
|-- scripts/
`-- README.md
```

## 1. Modules

```text
modules/
|-- networking/
|-- compute/
|-- database/
|-- monitoring/
`-- security/
```

### Purpose

The `modules/` directory contains reusable Terraform building blocks.

These modules are **not actual deployments**. They are reusable infrastructure templates.

Think of modules like:

- Reusable classes in programming
- Reusable services in microservices
- Reusable Helm charts in Kubernetes

### Core Principle

A module should solve **one infrastructure problem**.

| Good module | Responsibility |
| --- | --- |
| `vnet` | Creates virtual network |
| `vmss` | Creates VM scale set |
| `aks` | Creates Kubernetes cluster |
| `firewall` | Creates firewall infrastructure |

### Bad Practice

Creating ultra-small meaningless modules.

```text
modules/
|-- subnet-association/
|-- route-association/
`-- nsg-rule/
```

Why this is bad:

- Too fragmented
- Hard to maintain
- Too many dependencies
- Complex orchestration
- Poor readability

### Good Practice

Group logically related infrastructure together.

```text
modules/networking/vnet/
```

This module may internally create:

- VNet
- Subnets
- NSGs
- Route tables
- Associations

These resources belong to one networking context.

## 1.1 Networking Modules

```text
networking/
|-- vnet/
|-- subnet/
|-- nsg/
|-- nat-gateway/
|-- load-balancer/
`-- firewall/
```

### Purpose

Contains reusable networking infrastructure modules.

### `vnet/`

Responsible for:

- Virtual networks
- Address spaces
- DNS configuration
- Optional subnet creation

Best practice: expose configurable subnet objects instead of hardcoded subnets.

Good:

```hcl
variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
  }))
}
```

Bad:

```hcl
resource "azurerm_subnet" "web" {
  name = "web-subnet"
}
```

Hardcoded values reduce reusability.

### `subnet/`

Usually used when:

- Subnet lifecycle differs from VNet
- Separate teams manage subnets
- Network segmentation is dynamic

Avoid creating one subnet module per subnet type.

Bad:

```text
web-subnet-module/
db-subnet-module/
api-subnet-module/
```

### `nsg/`

Responsible for:

- NSGs
- NSG rules
- Associations

Best practice: use dynamic rules.

Good:

```hcl
variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}
```

### `nat-gateway/`

Responsible for:

- NAT Gateway
- Public IP association
- Subnet association

Best practice: keep outbound internet architecture centralized.

### `load-balancer/`

Responsible for:

- Frontend IPs
- Backend pools
- Health probes
- Rules
- NAT rules

Best practice: separate internal and external load balancers using variables.

### `firewall/`

Responsible for:

- Azure Firewall
- Firewall Policy
- DNAT
- Network rules
- Application rules

Best practice: use centralized firewall architecture.

## 1.2 Compute Modules

```text
compute/
|-- vm/
|-- vmss/
|-- aks/
`-- app-service/
```

### `vm/`

Used for:

- Bastion hosts
- Jump servers
- Utility servers
- Monitoring VMs

Best practice: avoid embedding application deployment logic inside the VM module.

Bad:

```text
install nginx
deploy application
configure app
```

Terraform should provision infrastructure. Use these tools for application deployment:

- Ansible
- Cloud-init
- Packer
- CI/CD
- Configuration management

### `vmss/`

Responsible for:

- VM Scale Sets
- Autoscaling
- Load Balancer integration

Best practice: use autoscaling policies separately and avoid tightly coupling scaling logic.

### `aks/`

Responsible for:

- AKS cluster
- Node pools
- RBAC
- Networking
- Monitoring integration

Best practice: keep cluster creation and Kubernetes workloads separate.

Terraform creates the cluster. Helm or Argo CD deploys applications.

### `app-service/`

Responsible for:

- Azure App Services
- App Service Plans
- Runtime configuration

## 1.3 Database Modules

```text
database/
|-- mysql/
|-- postgres/
`-- cosmosdb/
```

### Purpose

Contains reusable database infrastructure modules.

### Best Practices

Separate the database layer. Do not tightly couple databases with applications.

Bad:

```text
modules/app-with-postgres/
```

Good:

```text
modules/database/postgres/
modules/applications/api/
```

Use outputs carefully. Expose:

- Connection endpoints
- IDs
- Private DNS information

Avoid exposing secrets.

Bad:

```hcl
output "db_password" {
  value = var.password
}
```

Store secrets in:

- Azure Key Vault
- Vault
- Secret Manager

Do not store secrets in Terraform outputs or state.

## 1.4 Monitoring Modules

```text
monitoring/
|-- log-analytics/
|-- azure-monitor/
`-- alerts/
```

### Purpose

Contains centralized observability infrastructure.

### Best Practices

Centralize monitoring and avoid per-service monitoring duplication.

Good:

- Shared Log Analytics workspace
- Central alerting
- Central dashboards

### `alerts/`

Responsible for:

- Metric alerts
- Action groups
- Email notifications
- Webhook integrations

## 1.5 Security Modules

```text
security/
|-- keyvault/
|-- managed-identity/
`-- role-assignments/
```

### Purpose

Contains centralized security infrastructure.

### `keyvault/`

Responsible for:

- Secrets
- Certificates
- Encryption keys

Best practice: never hardcode secrets.

Bad:

```hcl
admin_password = "Password123"
```

Good:

```hcl
data "azurerm_key_vault_secret" "db" {}
```

### `managed-identity/`

Responsible for:

- System-assigned identity
- User-assigned identity

Best practice: prefer Managed Identity over service principals or static credentials.

### `role-assignments/`

Responsible for:

- RBAC
- IAM assignments

Best practice: use the least privilege principle.

Avoid:

- `Contributor` everywhere
- `Owner` everywhere

## 2. Environments

```text
environments/
|-- dev/
|-- staging/
`-- prod/
```

### Purpose

Contains **actual deployments**. This is where modules are used.

### Important Concept

Modules are reusable templates. Environments are real infrastructure deployments.

Example:

```text
environments/prod/networking/
```

This may deploy:

- Production VNets
- Production firewall
- Production load balancers

The deployment uses reusable modules.

### Environment Isolation Best Practice

Each environment should have:

- Separate state
- Separate variables
- Separate backend
- Separate secrets
- Separate approvals

### Bad Practice

Sharing the same state between environments.

Bad:

```text
terraform.tfstate
```

For:

- `dev`
- `staging`
- `prod`

This creates:

- High blast radius
- Accidental production modification
- Dangerous applies

### Good Practice

Use separate states.

Good:

```text
dev-networking.tfstate
prod-networking.tfstate
```

### Example Structure

```text
environments/
`-- prod/
    |-- networking/
    |-- platform/
    `-- applications/
```

### `networking/`

Deploys foundational networking.

Examples:

- VNets
- Firewall
- NAT Gateway
- Route tables

### `platform/`

Deploys shared platform infrastructure.

Examples:

- AKS
- VMSS
- Monitoring
- Databases

### `applications/`

Deploys application-level infrastructure.

Examples:

- Ingress
- DNS mappings
- Application services

### Layering Best Practice

#### Layer 1 - Foundation

Rarely changes.

- Networking
- Security
- DNS

#### Layer 2 - Platform

Shared infrastructure.

- AKS
- Databases
- Monitoring

#### Layer 3 - Applications

Frequently changing workloads.

- Microservices
- Ingress
- Applications

### Why Layering Matters

Benefits:

- Reduced blast radius
- Smaller plans
- Faster applies
- Better team ownership
- Safer deployments

## 3. Global

```text
global/
|-- backend/
|-- providers/
`-- policies/
```

### Purpose

Contains shared global Terraform configuration.

### `backend/`

Contains backend configuration.

Example:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateprod"
    container_name       = "tfstate"
    key                  = "prod-networking.tfstate"
  }
}
```

Best practices:

- Always use remote state.
- Enable state locking to prevent concurrent modifications.

Bad:

```text
local terraform.tfstate
```

Good:

- Azure Storage Account
- S3
- Terraform Cloud

### `providers/`

Contains provider configuration.

Example:

```hcl
provider "azurerm" {
  features {}
}
```

Best practice: pin provider versions.

Good:

```hcl
version = "~> 4.0"
```

Bad:

```text
latest
```

### `policies/`

Contains governance policies.

Examples:

- Azure Policies
- Sentinel
- OPA
- Compliance rules

## 4. Scripts

The `scripts/` directory contains automation scripts.

Examples:

- Bootstrap scripts
- Helper scripts
- Validation scripts
- CI/CD helpers

Best practice: keep scripts stateless and avoid environment-specific hardcoding.

## 5. Standard Module Internal Structure

Example:

```text
modules/networking/vnet/
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- locals.tf
|-- data.tf
|-- versions.tf
|-- README.md
|-- examples/
`-- tests/
```

### `main.tf`

Contains primary resources.

### `variables.tf`

Defines input variables. This acts like the module API contract.

### `outputs.tf`

Exports reusable outputs.

### `locals.tf`

Contains reusable computed values.

Good:

```hcl
locals {
  common_tags = {
    env = var.environment
  }
}
```

### `data.tf`

Contains data source lookups.

Good:

```hcl
data "azurerm_client_config" "current" {}
```

### `versions.tf`

Contains:

- Terraform version
- Provider versions

### `README.md`

Mandatory for production modules.

Should contain:

- Purpose
- Inputs
- Outputs
- Examples
- Usage
- Limitations

### `examples/`

Contains sample usage.

Critical for:

- Onboarding
- Testing
- Documentation

### `tests/`

Contains:

- Terratest
- Integration tests
- Validation tests

## Terraform State Best Practices

Never use one massive state file.

Always separate state by:

- Environment
- Layer
- Ownership
- Lifecycle

Good examples:

```text
prod-networking.tfstate
prod-platform.tfstate
prod-apps.tfstate
```

## Naming Convention Best Practices

Good examples:

```text
rg-prod-network-centralindia
vnet-prod-hub-centralindia
vmss-prod-api-centralindia
```

Include:

- Environment
- Workload
- Region

## Variable Design Best Practices

Bad:

```hcl
variable "subnet1" {}
variable "subnet2" {}
```

Good:

```hcl
variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
  }))
}
```

## Security Best Practices

Never:

- Hardcode secrets
- Expose secrets in outputs
- Commit `tfvars` files with secrets
- Store credentials in Git

Always use:

- Key Vault
- Managed Identity
- Secret managers
- CI/CD secret stores

## CI/CD Best Practices

Use separate stages:

1. `fmt`
2. `validate`
3. `lint`
4. `plan`
5. Manual approval
6. `apply`

Never automatically apply production changes without approval.

## Git Best Practices

Use a separate branch strategy.

Examples:

- `main`
- `develop`
- `feature/*`

Protect production by requiring:

- Pull requests
- Approvals
- Plan reviews

## Common Anti-Patterns

### 1. Giant Monolithic Terraform

Bad:

```text
10000-line main.tf
```

### 2. Copy-Paste Infrastructure

Bad:

```text
dev-vnet.tf
prod-vnet.tf
```

With duplicated code.

### 3. Hardcoded Values

Bad:

```hcl
location = "Central India"
```

Inside a reusable module.

### 4. Mixing App Deployment with Infrastructure

Bad Terraform behavior:

- Installs app
- Configures runtime
- Deploys binaries

Terraform should provision infrastructure.

### 5. Shared Production State

This is extremely dangerous.

### 6. No Module Versioning

Always version modules.

Good:

```hcl
source = "git::https://github.com/org/modules.git//networking/vnet?ref=v1.0.0"
```

## Recommended Enterprise Evolution Path

### Phase 1

Simple reusable modules.

### Phase 2

Environment separation.

### Phase 3

Remote state and CI/CD.

### Phase 4

Module versioning.

### Phase 5

Platform engineering model.

### Phase 6

GitOps and policy-as-code.

## Final Architecture Mental Model

```text
Environment
    |
    v
Root Module
    |
    v
Reusable Terraform Modules
    |
    v
Cloud Resources
```

Or:

```text
Production Deployment
    |
    v
Versioned Modules
    |
    v
Infrastructure Provisioning
```

This is how mature Terraform systems are designed in production environments.
