locals {
  name_suffix = "${var.environment}-${var.region_code}"

  tags = {
    environment = var.environment
    repo        = "terraform-azure-aks-clusters-weu"
    managed-by  = "terraform"
  }

  clusters = {
    for id, cluster in var.clusters : id => merge(cluster, {
      name = "aks-${var.environment}-${id}-${var.region_code}"
    })
  }
}
