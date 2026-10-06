output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "clusters" {
  description = "Per cluster: name, version and the command to configure kubectl."
  value = {
    for id, cluster in module.aks : id => {
      name                    = cluster.cluster_name
      kubernetes_version      = cluster.current_kubernetes_version
      node_resource_group     = cluster.node_resource_group
      get_credentials_command = cluster.get_credentials_command
    }
  }
}
