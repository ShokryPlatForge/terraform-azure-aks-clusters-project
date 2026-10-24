# Everything that differs between environments lives in this file.
environment = "dev"
# westeurope is the selected lab region. Confirm zonal SKU availability before
# switching the capacity tier to resilience.
location           = "westeurope"
region_code        = "weu"
vnet_address_space = "10.40.0.0/16"

clusters = {
  "01" = {
    name        = "aks-astronomyshop"
    subnet_cidr = "10.40.0.0/22"

    # Pin after checking: az aks get-versions --location westeurope -o table
    # aks_cluster_version = "1.33"

    system_vm_size    = "Standard_D2s_v5"
    system_node_count = 1

    node_pools_config = {
      apps = {
        vm_size              = "Standard_D4s_v5"
        auto_scaling_enabled = true
        min_count            = 2
        max_count            = 4
        zones                = ["1", "2", "3"]
      }
    }

    # Lock the API server to your IP (curl -s https://ifconfig.me):
    # api_server_authorized_ip_ranges = ["203.0.113.7/32"]
  }
}
