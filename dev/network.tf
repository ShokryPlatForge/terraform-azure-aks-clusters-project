# In terraform-rancher-clusters-usw2 the VPC comes from a separate network
# workspace (remote_state_network.tf). Here the environment owns its VNet until
# it is worth splitting into its own stack.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-aks-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "cluster" {
  for_each = local.clusters

  name                 = "snet-${each.value.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.subnet_cidr]
}
