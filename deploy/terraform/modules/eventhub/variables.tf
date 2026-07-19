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

variable "sku" {
  description = "SKU for Event Hub namespace"
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "Throughput units for Event Hub namespace"
  type        = number
  default     = 1
}

variable "event_hubs" {
  description = "Map of Event Hub configurations"
  type = map(object({
    partition_count   = number
    message_retention = number
  }))
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed to access Event Hub"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
