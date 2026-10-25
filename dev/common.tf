resource "azurerm_resource_group" "this" {
  name     = "rg-aks-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "aks_bootstrap_user_access_admin" {
  count                = var.aks_bootstrap_admin_object_id == "" ? 0 : 1
  scope                = azurerm_resource_group.this.id
  role_definition_name = "User Access Administrator"
  principal_id         = var.aks_bootstrap_admin_object_id
  principal_type       = "ServicePrincipal"
}
