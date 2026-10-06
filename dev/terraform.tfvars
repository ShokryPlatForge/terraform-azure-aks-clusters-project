# Everything that differs between environments lives in this file.
environment        = "dev"
# westeurope returned RequestDisallowedByAzure / locationineligible for this subscription.
location           = "northeurope"
region_code        = "neu"
vnet_address_space = "10.10.0.0/16"

clusters = {
  "01" = {
    subnet_cidr = "10.10.0.0/22"

    # Pin after checking: az aks get-versions --location northeurope -o table
    # aks_cluster_version = "1.33"

    system_vm_size    = "Standard_B2s"
    system_node_count = 1

    # Lock the API server to your IP (curl -s https://ifconfig.me):
    # api_server_authorized_ip_ranges = ["203.0.113.7/32"]
  }
}
