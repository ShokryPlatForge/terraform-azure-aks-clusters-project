# Everything that differs between environments lives in this file.
environment        = "dev"
# westeurope: locationineligible. northeurope: EC/M/NV only.
# eastus: GP SKUs via Standard DSv4 family (see az vm list-skus).
location           = "eastus"
region_code        = "eus"
vnet_address_space = "10.10.0.0/16"

clusters = {
  "01" = {
    subnet_cidr = "10.10.0.0/22"

    # PlatForge GKE pattern (docs/cloud/gcp-gke.md): small platform pool + dedicated app pool.
    # GKE lab dev: ~2 platform nodes + ≥2 app nodes with autoscale — capacity, not a trimmed chart.
    system_vm_size    = "Standard_D2s_v4"
    system_node_count = 1

    # Tenant workloads (full opentelemetry-demo). Needs total + DSv4 vCPU quota > 4 (portal/support if CLI quota update fails).
    node_pools_config = {
      apps = {
        vm_size              = "Standard_D4s_v4"
        auto_scaling_enabled = true
        min_count            = 2
        max_count            = 3
        node_labels          = { workload = "apps" }
      }
    }

    # Lock the API server to your IP (curl -s https://ifconfig.me):
    # api_server_authorized_ip_ranges = ["203.0.113.7/32"]
  }
}
