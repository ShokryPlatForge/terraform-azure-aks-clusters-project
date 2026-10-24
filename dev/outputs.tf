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

output "key_vault" {
  value = {
    name = azurerm_key_vault.this.name
    id   = azurerm_key_vault.this.id
  }
}

output "workload_identities" {
  description = "Per cluster workload identities; client_id is used by Azure Workload Identity service-account annotations."
  value = {
    for id, cluster in module.aks : id => cluster.workload_identities
  }
}
