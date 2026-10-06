variable "environment" {
  description = "Environment name; used in every resource name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "region_code" {
  description = "Short region code used in names, e.g. weu for westeurope."
  type        = string
}

variable "vnet_address_space" {
  description = "VNet CIDR for this environment. Give every environment its own range so they can be peered later."
  type        = string
}

variable "clusters" {
  description = "Clusters in this environment, keyed by a two-digit id. The cluster is named aks-<environment>-<id>-<region_code>."
  type = map(object({
    subnet_cidr                     = string
    aks_cluster_version             = optional(string)
    sku_tier                        = optional(string, "Free")
    system_vm_size                  = optional(string, "Standard_B2s")
    system_node_count               = optional(number, 1)
    api_server_authorized_ip_ranges = optional(list(string), [])
    enable_node_auto_provisioning   = optional(bool, false)
    control_plane_logs_enabled      = optional(bool, false)
    admins                          = optional(map(string), {})
    read_only                       = optional(map(string), {})
    ns_admins = optional(map(object({
      principal_id = string
      namespaces   = list(string)
    })), {})
    node_pools_config = optional(map(object({
      vm_size              = optional(string)
      node_count           = optional(number)
      auto_scaling_enabled = optional(bool)
      min_count            = optional(number)
      max_count            = optional(number)
      node_labels          = optional(map(string))
      node_taints          = optional(list(string))
    })), {})
  }))

  validation {
    condition     = alltrue([for id, _ in var.clusters : can(regex("^[0-9]{2}$", id))])
    error_message = "clusters keys must be two digits, e.g. \"01\"."
  }

  validation {
    condition     = length(distinct([for c in values(var.clusters) : c.subnet_cidr])) == length(var.clusters)
    error_message = "Every cluster needs its own subnet_cidr."
  }
}
