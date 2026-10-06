# Everything that differs between environments lives in this file.
environment        = "dev"
# westeurope: locationineligible. northeurope: EC/M/NV only.
# eastus: this subscription has no B-series; smallest GP size in the AKS allow-list is D2s_v4.
#   az vm list-skus --location eastus --size Standard_D2s_v4 -o table
location           = "eastus"
region_code        = "eus"
vnet_address_space = "10.10.0.0/16"

clusters = {
  "01" = {
    subnet_cidr = "10.10.0.0/22"

    # Pin after checking: az aks get-versions --location eastus -o table
    # aks_cluster_version = "1.33"

    system_vm_size    = "Standard_D2s_v4"
    system_node_count = 1

    # Lock the API server to your IP (curl -s https://ifconfig.me):
    # api_server_authorized_ip_ranges = ["203.0.113.7/32"]
  }
}
