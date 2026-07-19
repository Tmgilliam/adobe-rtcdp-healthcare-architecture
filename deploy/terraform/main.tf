terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rtcdp-tfstate-rg"
    storage_account_name = "rtcdptfstate"
    container_name       = "tfstate"
    key                  = "rtcdp.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}

data "azurerm_client_config" "current" {}

locals {
  resource_prefix = "rtcdp-${var.environment}"
  common_tags = {
    Project     = "RTCDP Healthcare"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Platform Team"
    Compliance  = "HIPAA"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix

  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets

  tags = local.common_tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix
  tenant_id           = data.azurerm_client_config.current.tenant_id

  subnet_ids = [module.network.subnet_ids["aks"]]

  tags = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix

  private_endpoint_subnet_id = module.network.subnet_ids["private_endpoints"]

  containers = [
    "raw-ingestion",
    "processed",
    "archive",
    "consent-store"
  ]

  tags = local.common_tags
}

module "eventhub" {
  source = "./modules/eventhub"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix

  sku      = var.eventhub_sku
  capacity = var.eventhub_capacity

  event_hubs = {
    "patient-events" = {
      partition_count   = 4
      message_retention = 7
    }
    "engagement-events" = {
      partition_count   = 8
      message_retention = 3
    }
    "consent-events" = {
      partition_count   = 2
      message_retention = 7
    }
  }

  allowed_subnet_ids = [module.network.subnet_ids["aks"]]

  tags = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix

  kubernetes_version = var.kubernetes_version
  aks_subnet_id      = module.network.subnet_ids["aks"]

  default_node_pool = var.default_node_pool
  node_pools        = var.node_pools

  log_analytics_workspace_id = module.monitoring.workspace_id

  tags = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix

  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
