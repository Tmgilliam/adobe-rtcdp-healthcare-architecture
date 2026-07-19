variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "aks_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name       = string
    vm_size    = string
    node_count = number
    zones      = list(string)
  })
}

variable "node_pools" {
  description = "Additional node pool configurations"
  type = map(object({
    vm_size    = string
    node_count = number
    labels     = map(string)
    taints     = list(string)
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
