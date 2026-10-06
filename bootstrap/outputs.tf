output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "backend_hcl" {
  description = "Contents for backend.hcl at the repo root, shared by every environment."
  value       = <<-EOT
    subscription_id      = "${data.azurerm_client_config.current.subscription_id}"
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
  EOT
}
