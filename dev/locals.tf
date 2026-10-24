locals {
  name_suffix = "${var.environment}-${var.region_code}"

  tags = {
    environment = var.environment
    repo        = "terraform-azure-aks-clusters-project"
    managed-by  = "terraform"
  }

  clusters = {
    for id, cluster in var.clusters : id => merge(
      cluster,
      {
        name = coalesce(try(cluster.name, null), "aks-${var.environment}-${id}-${var.region_code}")
      },
      var.capacity_tier == "resilience" ? {
        system_vm_size    = "Standard_D4s_v5"
        system_node_count = 3
        system_zones      = ["1", "2", "3"]
        node_pools_config = {
          apps = {
            vm_size              = "Standard_D8s_v5"
            auto_scaling_enabled = true
            min_count            = 3
            max_count            = 6
            zones                = ["1", "2", "3"]
          }
        }
      } : {}
    )
  }
}
