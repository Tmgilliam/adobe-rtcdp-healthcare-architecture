environment = "staging"
location    = "eastus2"

vnet_address_space = ["10.1.0.0/16"]

subnets = {
  aks = {
    address_prefixes  = ["10.1.1.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub"]
  }
  private_endpoints = {
    address_prefixes = ["10.1.2.0/24"]
  }
  data = {
    address_prefixes  = ["10.1.3.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
}

kubernetes_version = "1.28"

default_node_pool = {
  name       = "system"
  vm_size    = "Standard_D4s_v3"
  node_count = 3
  zones      = ["1", "2"]
}

node_pools = {
  ingestion = {
    vm_size    = "Standard_D4s_v3"
    node_count = 2
    labels     = { workload = "ingestion" }
    taints     = []
  }
  transform = {
    vm_size    = "Standard_E4s_v3"
    node_count = 2
    labels     = { workload = "transform" }
    taints     = []
  }
}

eventhub_sku      = "Standard"
eventhub_capacity = 2

log_retention_days = 60
