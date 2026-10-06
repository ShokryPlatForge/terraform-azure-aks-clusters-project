# Plans this environment with its real terraform.tfvars against a mocked
# Azure provider: catches typos and module guard-rail failures before you
# touch your subscription.  Run: terraform init -backend=false && terraform test

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
