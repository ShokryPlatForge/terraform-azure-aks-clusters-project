# One-time: apps node pool was created with `az aks nodepool add` before Terraform defined it.
# Run apply in TFC to import, then delete this file and commit (avoid re-import on later plans).
import {
  to = module.aks["01"].azurerm_kubernetes_cluster_node_pool.this["apps"]
  id = "/subscriptions/5ed125b5-6b38-4e35-9ae5-5a76949d4193/resourceGroups/rg-aks-dev-eus/providers/Microsoft.ContainerService/managedClusters/aks-dev-01-eus/agentPools/apps"
}
