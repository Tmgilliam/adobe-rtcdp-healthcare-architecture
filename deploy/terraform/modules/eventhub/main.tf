resource "azurerm_eventhub_namespace" "main" {
  name                = "${var.resource_prefix}-events"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  auto_inflate_enabled     = var.sku == "Standard" ? true : false
  maximum_throughput_units = var.sku == "Standard" ? 10 : null

  network_rulesets {
    default_action                 = "Deny"
    trusted_service_access_enabled = true

    dynamic "virtual_network_rule" {
      for_each = var.allowed_subnet_ids
      content {
        subnet_id = virtual_network_rule.value
      }
    }
  }

  tags = var.tags
}

resource "azurerm_eventhub" "hubs" {
  for_each = var.event_hubs

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention
}

resource "azurerm_eventhub_consumer_group" "default" {
  for_each = var.event_hubs

  name                = "default-consumer"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.hubs[each.key].name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "send" {
  for_each = var.event_hubs

  name                = "${each.key}-send"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.hubs[each.key].name
  resource_group_name = var.resource_group_name

  listen = false
  send   = true
  manage = false
}

resource "azurerm_eventhub_authorization_rule" "listen" {
  for_each = var.event_hubs

  name                = "${each.key}-listen"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.hubs[each.key].name
  resource_group_name = var.resource_group_name

  listen = true
  send   = false
  manage = false
}
