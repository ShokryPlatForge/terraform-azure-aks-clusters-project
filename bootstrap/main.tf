data "azurerm_client_config" "current" {}

locals {
  # Storage account names are global, 3-24 lowercase alphanumerics. Deriving
  # the suffix from the subscription keeps it unique and stable across re-runs.
  storage_account_name = "tfstate${substr(replace(data.azurerm_client_config.current.subscription_id, "-", ""), 0, 12)}"

  tags = {
    managed-by = "terraform"
    purpose    = "terraform-state"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Versioning plus soft delete lets you roll back a corrupted or deleted state file.
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }

    container_delete_retention_policy {
      days = 14
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_management_lock" "tfstate" {
  count = var.delete_lock_enabled ? 1 : 0

  name       = "protect-terraform-state"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state for every environment. Remove this lock only if you really mean to delete all state."
}
