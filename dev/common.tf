resource "azurerm_resource_group" "this" {
  name     = "rg-aks-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}
