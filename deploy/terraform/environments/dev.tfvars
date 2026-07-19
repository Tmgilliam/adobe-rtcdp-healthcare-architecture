environment = "dev"
location    = "eastus2"

vnet_address_space = ["10.0.0.0/16"]

subnets = {
  aks = {
    address_prefixes  = ["10.0.1.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub"]
  }
  private_endpoints = {
    address_prefixes = ["10.0.2.0/24"]
  }
  data = {
    address_prefixes  = ["10.0.3.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
}

kubernetes_version = "1.28"

default_node_pool = {
  name       = "system"
  vm_size    = "Standard_D2s_v3"
  node_count = 2
  zones      = ["1"]
}

node_pools = {
  workload = {
    vm_size    = "Standard_D4s_v3"
    node_count = 2
    labels     = { workload = "general" }
    taints     = []
  }
}

eventhub_sku      = "Standard"
eventhub_capacity = 1

log_retention_days = 30
