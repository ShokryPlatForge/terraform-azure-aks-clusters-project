# Plans this environment with mocked Azure (no subscription). The AKS module is
# pulled from app.terraform.io — run `terraform login` first, or use
# clusters.tf.local.example for fully offline plans.
#
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-00000000aaaa"
      object_id       = "00000000-0000-0000-0000-00000000bbbb"
      subscription_id = "00000000-0000-0000-0000-00000000cccc"
      client_id       = "00000000-0000-0000-0000-00000000dddd"
    }
  }
}

mock_provider "time" {}

run "environment_plans_cleanly" {
  command = plan

  assert {
    condition     = length(module.aks) == length(var.clusters)
    error_message = "Every entry in clusters should produce one AKS module instance."
  }

  assert {
    condition     = alltrue([for id, cluster in local.clusters : startswith(cluster.name, "aks-${var.environment}-")])
    error_message = "Cluster names must carry the environment name."
  }
}
