# Everything that differs between environments lives in this file.
environment        = "dev"
# westeurope: locationineligible. northeurope: no B/D SKUs (EC/M/NV only = $$$).
# eastus: usually cheapest + Standard_B2s for personal subs. Verify before apply:
#   az vm list-skus --location eastus --size Standard_B2s -o table
# If eastus fails (ineligible), try: centralus, southcentralus, westus2, swedencentral
location           = "eastus"
region_code        = "eus"
vnet_address_space = "10.10.0.0/16"

clusters = {
  "01" = {
    subnet_cidr = "10.10.0.0/22"

    # Pin after checking: az aks get-versions --location eastus -o table
    # aks_cluster_version = "1.33"

    system_vm_size    = "Standard_B2s"
    system_node_count = 1

    # Lock the API server to your IP (curl -s https://ifconfig.me):
    # api_server_authorized_ip_ranges = ["203.0.113.7/32"]
  }
}
