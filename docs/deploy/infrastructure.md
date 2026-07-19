# Infrastructure Guide

This guide covers the Terraform-based infrastructure deployment for the RTCDP integration layer on Azure.

## Architecture Overview

The infrastructure consists of three main layers:

1. **Network Layer**: VNet, subnets, NSGs, private endpoints
2. **Compute Layer**: AKS cluster for containerized workloads
3. **Data Layer**: Storage accounts, Event Hubs, Key Vault

## Terraform Module Structure

```
deploy/terraform/
├── main.tf                 # Root module
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── modules/
│   ├── network/           # VNet, subnets, NSGs
│   ├── aks/               # Kubernetes cluster
│   ├── storage/           # Blob storage, containers
│   ├── eventhub/          # Event Hub namespace
│   ├── keyvault/          # Key Vault + secrets
│   └── monitoring/        # Log Analytics, alerts
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

## Network Configuration

```hcl
module "network" {
  source = "./modules/network"

  resource_group_name = var.resource_group_name
  location            = var.location
  
  vnet_address_space  = ["10.0.0.0/16"]
  
  subnets = {
    aks = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    private_endpoints = {
      address_prefixes = ["10.0.2.0/24"]
    }
    data = {
      address_prefixes = ["10.0.3.0/24"]
      delegation = "Microsoft.Storage/storageAccounts"
    }
  }

  tags = var.tags
}
```

## AKS Cluster Configuration

```hcl
module "aks" {
  source = "./modules/aks"

  cluster_name        = "rtcdp-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  kubernetes_version  = "1.28"
  
  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D4s_v3"
    node_count          = 3
    availability_zones  = ["1", "2", "3"]
    vnet_subnet_id      = module.network.subnet_ids["aks"]
  }

  additional_node_pools = {
    ingestion = {
      vm_size    = "Standard_D8s_v3"
      node_count = 2
      labels     = { workload = "ingestion" }
      taints     = []
    }
    transform = {
      vm_size    = "Standard_E4s_v3"
      node_count = 3
      labels     = { workload = "transform" }
      taints     = []
    }
  }

  network_profile = {
    network_plugin     = "azure"
    network_policy     = "calico"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }

  identity_type = "UserAssigned"
  
  enable_azure_policy     = true
  enable_oms_agent        = true
  log_analytics_workspace_id = module.monitoring.workspace_id

  tags = var.tags
}
```

## Storage Configuration

```hcl
module "storage" {
  source = "./modules/storage"

  storage_account_name = "rtcdp${var.environment}data"
  resource_group_name  = var.resource_group_name
  location             = var.location

  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  # HIPAA compliance settings
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  
  # Encryption
  infrastructure_encryption_enabled = true
  
  containers = {
    "raw-ingestion" = {
      access_type = "private"
    }
    "processed" = {
      access_type = "private"
    }
    "archive" = {
      access_type = "private"
    }
  }

  # Lifecycle management
  lifecycle_rules = [
    {
      name    = "archive-old-data"
      enabled = true
      filters = { prefix_match = ["processed/"] }
      actions = {
        base_blob = {
          tier_to_cool_after_days    = 30
          tier_to_archive_after_days = 90
          delete_after_days          = 365
        }
      }
    }
  ]

  # Private endpoint
  private_endpoint_subnet_id = module.network.subnet_ids["private_endpoints"]

  tags = var.tags
}
```

## Event Hub Configuration

```hcl
module "eventhub" {
  source = "./modules/eventhub"

  namespace_name      = "rtcdp-${var.environment}-events"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku      = "Standard"
  capacity = 2

  event_hubs = {
    "patient-events" = {
      partition_count   = 4
      message_retention = 7
      consumer_groups   = ["transform-workers", "monitoring"]
    }
    "engagement-events" = {
      partition_count   = 8
      message_retention = 3
      consumer_groups   = ["activation-service"]
    }
  }

  # Network rules
  network_rulesets = {
    default_action = "Deny"
    virtual_network_rules = [
      { subnet_id = module.network.subnet_ids["aks"] }
    ]
  }

  tags = var.tags
}
```

## Key Vault Configuration

```hcl
module "keyvault" {
  source = "./modules/keyvault"

  key_vault_name      = "rtcdp-${var.environment}-kv"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name = "premium"  # Required for HSM-backed keys

  # HIPAA compliance
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Network
  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [module.network.subnet_ids["aks"]]
  }

  # Access policies set via RBAC
  enable_rbac_authorization = true

  tags = var.tags
}
```

## Deployment Commands

```bash
# Initialize with backend configuration
terraform init \
  -backend-config="resource_group_name=rtcdp-tfstate-rg" \
  -backend-config="storage_account_name=rtcdptfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${ENVIRONMENT}.tfstate"

# Validate configuration
terraform validate

# Plan with specific environment
terraform plan \
  -var-file="environments/${ENVIRONMENT}.tfvars" \
  -out="${ENVIRONMENT}.tfplan"

# Apply the plan
terraform apply "${ENVIRONMENT}.tfplan"

# Destroy (with confirmation)
terraform destroy -var-file="environments/${ENVIRONMENT}.tfvars"
```

## Cost Estimation

| Resource | SKU | Monthly Cost (Est.) |
|----------|-----|---------------------|
| AKS Cluster (8 nodes) | D4s_v3, D8s_v3, E4s_v3 | $1,200 |
| Storage Account | Standard GRS | $100 |
| Event Hubs | Standard (2 TU) | $450 |
| Key Vault | Premium | $50 |
| Log Analytics | Pay-as-you-go | $200 |
| **Total** | | **~$2,000/month** |

!!! note "Cost Optimization"
    Development environments use smaller SKUs and single-zone deployment, reducing costs by ~60%.
