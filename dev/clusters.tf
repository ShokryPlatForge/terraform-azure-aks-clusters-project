module "aks" {
  source   = "../../terraform-azure-aks-module"
  for_each = local.clusters

  cluster_name        = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  environment         = var.environment
  aks_cluster_version = each.value.aks_cluster_version
  sku_tier            = each.value.sku_tier

  subnet_aks_id                   = azurerm_subnet.cluster[each.key].id
  api_server_authorized_ip_ranges = each.value.api_server_authorized_ip_ranges

  system_node_pool = {
    vm_size    = each.value.system_vm_size
    node_count = each.value.system_node_count
  }

  # Unset (null) pool fields fall back to the module defaults.
  node_pools_config = each.value.node_pools_config

  enable_node_auto_provisioning = each.value.enable_node_auto_provisioning

  admins    = each.value.admins
  read_only = each.value.read_only
  ns_admins = each.value.ns_admins

  control_plane_logs = {
    enabled = each.value.control_plane_logs_enabled
  }

  tags = local.tags
}
