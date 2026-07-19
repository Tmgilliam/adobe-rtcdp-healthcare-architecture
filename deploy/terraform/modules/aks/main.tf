resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.resource_prefix}-aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.resource_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.resource_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.node_count
    zones               = var.default_node_pool.zones
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    enable_auto_scaling = false

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  azure_policy_enabled = true

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "pools" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = 128

  node_labels = each.value.labels

  dynamic "node_taints" {
    for_each = each.value.taints
    content {
      key    = split("=", split(":", node_taints.value)[0])[0]
      value  = split("=", split(":", node_taints.value)[0])[1]
      effect = split(":", node_taints.value)[1]
    }
  }

  tags = var.tags
}
