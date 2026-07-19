output "namespace_id" {
  description = "ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.name
}

output "connection_string" {
  description = "Connection string for the namespace"
  value       = azurerm_eventhub_namespace.main.default_primary_connection_string
  sensitive   = true
}

output "event_hub_ids" {
  description = "Map of Event Hub names to IDs"
  value       = { for k, v in azurerm_eventhub.hubs : k => v.id }
}
