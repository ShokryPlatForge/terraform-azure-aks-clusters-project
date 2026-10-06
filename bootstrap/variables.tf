variable "location" {
  description = "Region for the state storage account."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group that holds the Terraform state storage."
  type        = string
  default     = "rg-tfstate"
}

variable "delete_lock_enabled" {
  description = "Put a CanNotDelete lock on the state storage account so it cannot be removed by accident."
  type        = bool
  default     = true
}
