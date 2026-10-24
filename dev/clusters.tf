module "aks" {
  source  = "app.terraform.io/PlatformForge/aks/azurerm"
  version = "1.1.0"

  for_each = local.clusters

  cluster_name        = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  environment         = var.environment
  aks_cluster_version = each.value.aks_cluster_version
  sku_tier            = each.value.sku_tier

  subnet_aks_id                   = azurerm_subnet.cluster[each.key].id
  api_server_authorized_ip_ranges = length(each.value.api_server_authorized_ip_ranges) > 0 ? each.value.api_server_authorized_ip_ranges : var.default_api_server_authorized_ip_ranges

  system_node_pool = {
    vm_size    = each.value.system_vm_size
    node_count = each.value.system_node_count
    zones      = each.value.system_zones
  }

  node_pools_config = each.value.node_pools_config

  workload_identities = {
    external-secrets = {
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_assignments = [{
        scope                = azurerm_key_vault.this.id
        role_definition_name = "Key Vault Secrets User"
      }]
    }
  }

  enable_node_auto_provisioning = each.value.enable_node_auto_provisioning

  admins = merge(
    each.value.admins,
    var.aks_bootstrap_admin_object_id == "" ? {} : {
      github_actions = var.aks_bootstrap_admin_object_id
    }
  )
  read_only = each.value.read_only
  ns_admins = each.value.ns_admins

  control_plane_logs = {
    enabled = each.value.control_plane_logs_enabled
  }

  tags = local.tags
}
