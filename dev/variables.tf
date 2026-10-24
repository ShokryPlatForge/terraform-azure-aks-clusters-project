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

variable "capacity_tier" {
  description = "Lab capacity profile."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "resilience"], var.capacity_tier)
    error_message = "capacity_tier must be dev or resilience."
  }
}

variable "default_api_server_authorized_ip_ranges" {
  description = "Runtime operator/GitHub CIDRs used when a cluster entry does not define its own API allow-list."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.default_api_server_authorized_ip_ranges : can(cidrhost(cidr, 0))])
    error_message = "Every default API authorized network must be a valid CIDR."
  }
}

variable "vnet_address_space" {
  description = "VNet CIDR for this environment. Give every environment its own range so they can be peered later."
  type        = string
}

variable "key_vault_name" {
  description = "Azure Key Vault used for AKS platform bootstrap and future External Secrets integration."
  type        = string
  default     = "kv-astronomyshop-weu"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 characters using letters, numbers or hyphens."
  }
}

variable "aks_bootstrap_admin_object_id" {
  description = "Entra object ID of the GitHub Actions AKS bootstrap service principal."
  type        = string
  default     = ""
}

variable "clusters" {
  description = "Clusters in this environment, keyed by a two-digit id. The cluster is named aks-<environment>-<id>-<region_code>."
  type = map(object({
    name                            = optional(string)
    subnet_cidr                     = string
    aks_cluster_version             = optional(string)
    sku_tier                        = optional(string, "Free")
    system_vm_size                  = optional(string, "Standard_B2s")
    system_node_count               = optional(number, 1)
    system_zones                    = optional(list(string))
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
      zones                = optional(list(string))
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
