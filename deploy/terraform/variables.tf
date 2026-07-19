variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation        = optional(string, null)
  }))
  default = {
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
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name       = string
    vm_size    = string
    node_count = number
    zones      = list(string)
  })
  default = {
    name       = "system"
    vm_size    = "Standard_D4s_v3"
    node_count = 3
    zones      = ["1", "2", "3"]
  }
}

variable "node_pools" {
  description = "Additional node pool configurations"
  type = map(object({
    vm_size    = string
    node_count = number
    labels     = map(string)
    taints     = list(string)
  }))
  default = {
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
}

variable "eventhub_sku" {
  description = "Event Hub namespace SKU"
  type        = string
  default     = "Standard"
}

variable "eventhub_capacity" {
  description = "Event Hub throughput units"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 90
}
