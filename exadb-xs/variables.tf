# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "exadb-xs"
}

variable "enable_output" {
  description = "Whether Terraform should enable module outputs."
  type        = bool
  default     = true
}

variable "exadb_xs_configuration" {
  description = "ExaDB-XS storage vault and VM cluster configuration. Exascale DB Storage Vaults are OCI Database resources, not OCI Vault/KMS vaults."
  type = object({
    default_compartment_id = optional(string)
    default_defined_tags   = optional(map(string), {})
    default_freeform_tags  = optional(map(string), {})

    exascale_db_storage_vaults = optional(map(object({
      availability_domain                = string
      display_name                       = string
      high_capacity_database_storage_gbs = number
      compartment_id                     = optional(string)
      additional_flash_cache_in_percent  = optional(number)
      autoscale_limit_in_gbs             = optional(number)
      description                        = optional(string)
      exadata_infrastructure_id          = optional(string)
      is_autoscale_enabled               = optional(bool)
      subscription_id                    = optional(string)
      time_zone                          = optional(string)
      defined_tags                       = optional(map(string))
      freeform_tags                      = optional(map(string))
    })), {})

    exadb_vm_clusters = optional(map(object({
      availability_domain          = string
      backup_subnet_id             = string
      display_name                 = string
      exascale_db_storage_vault_id = string
      grid_image_id                = string
      hostname                     = string
      shape                        = string
      ssh_public_keys              = list(string)
      subnet_id                    = string
      node_names                   = list(string)
      node_config = object({
        enabled_ecpu_count_per_node              = number
        total_ecpu_count_per_node                = number
        vm_file_system_storage_size_gbs_per_node = number
      })

      compartment_id         = optional(string)
      backup_network_nsg_ids = optional(list(string), [])
      cluster_name           = optional(string)
      data_collection_options = optional(object({
        is_diagnostics_events_enabled = optional(bool)
        is_health_monitoring_enabled  = optional(bool)
        is_incident_logs_enabled      = optional(bool)
      }))
      defined_tags               = optional(map(string))
      domain                     = optional(string)
      freeform_tags              = optional(map(string))
      license_model              = optional(string)
      nsg_ids                    = optional(list(string), [])
      private_zone_id            = optional(string)
      scan_listener_port_tcp     = optional(number)
      scan_listener_port_tcp_ssl = optional(number)
      security = optional(object({
        zpr_attributes = optional(list(object({
          namespace  = optional(string, "oracle-zpr")
          attr_name  = string
          attr_value = string
          mode       = optional(string, "enforce")
        })), [])
      }))
      shape_attribute = optional(string)
      subscription_id = optional(string)
      system_version  = optional(string)
      time_zone       = optional(string)
    })), {})
  })
  default = null

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for vault in values(var.exadb_xs_configuration.exascale_db_storage_vaults) :
      vault.exadata_infrastructure_id != null ? (
        vault.high_capacity_database_storage_gbs >= 2000
        ) : (
        vault.high_capacity_database_storage_gbs >= 300 &&
        vault.high_capacity_database_storage_gbs <= 100000
      ) &&
      trimspace(vault.display_name) != "" &&
      (vault.autoscale_limit_in_gbs == null || vault.autoscale_limit_in_gbs >= vault.high_capacity_database_storage_gbs)
    ])
    error_message = "Storage vault display_name must be nonempty. ExaDB-XS storage vaults without exadata_infrastructure_id must set high_capacity_database_storage_gbs between 300 and 100000. Vaults with exadata_infrastructure_id must set at least 2000 GB; their maximum remains Dedicated Infrastructure service-dependent. autoscale_limit_in_gbs, when set, must not be lower than high_capacity_database_storage_gbs."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for vault in values(var.exadb_xs_configuration.exascale_db_storage_vaults) :
      vault.additional_flash_cache_in_percent == null || (
        vault.additional_flash_cache_in_percent == 0 || (
          vault.additional_flash_cache_in_percent >= 34 &&
          vault.additional_flash_cache_in_percent <= 300
        )
      )
    ])
    error_message = "exadb_xs_configuration.exascale_db_storage_vaults[*].additional_flash_cache_in_percent must be zero (no additional Flash Cache) or between 34 and 300 when specified."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      trimspace(cluster.display_name) != "" &&
      length(cluster.node_names) > 0 &&
      length(cluster.node_names) <= 10 &&
      length(distinct([for name in cluster.node_names : trimspace(name)])) == length(cluster.node_names) &&
      alltrue([for name in cluster.node_names : trimspace(name) != "" && !can(regex("\\s", name))])
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].display_name must be nonempty, and node_names must contain from 1 to 10 nonempty, unique names without whitespace."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      (
        cluster.node_config.enabled_ecpu_count_per_node == 0 || (
          cluster.node_config.enabled_ecpu_count_per_node >= 8 &&
          cluster.node_config.enabled_ecpu_count_per_node <= 200 &&
          cluster.node_config.enabled_ecpu_count_per_node % 4 == 0
        )
      ) &&
      cluster.node_config.total_ecpu_count_per_node >= 8 &&
      cluster.node_config.total_ecpu_count_per_node <= 200 &&
      cluster.node_config.total_ecpu_count_per_node % 4 == 0 &&
      cluster.node_config.enabled_ecpu_count_per_node <= cluster.node_config.total_ecpu_count_per_node &&
      cluster.node_config.vm_file_system_storage_size_gbs_per_node >= (
        cluster.shape_attribute == "BLOCK_STORAGE" ? 260 : 220
      )
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].node_config.enabled_ecpu_count_per_node must be zero or from 8 to 200 in multiples of 4. total_ecpu_count_per_node must be from 8 to 200 in multiples of 4 and must not be below enabled_ecpu_count_per_node. vm_file_system_storage_size_gbs_per_node must be at least 220 GB for Smart Storage (including the provider default) or 260 GB for Block Storage."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      length(cluster.ssh_public_keys) > 0 && alltrue([for key in cluster.ssh_public_keys : trimspace(key) != ""])
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].ssh_public_keys must contain at least one nonempty SSH public key."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      cluster.shape_attribute == null || contains(["SMART_STORAGE", "BLOCK_STORAGE"], cluster.shape_attribute)
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].shape_attribute must be SMART_STORAGE or BLOCK_STORAGE when specified."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      can(regex("^[A-Za-z][A-Za-z0-9-]{0,11}$", cluster.hostname)) &&
      (cluster.cluster_name == null || can(regex("^[A-Za-z][A-Za-z0-9-]{0,10}$", cluster.cluster_name))) &&
      (cluster.domain == null || length("${cluster.hostname}.${cluster.domain}") <= 63)
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].hostname must start with a letter and use at most 12 letters, digits, or hyphens. cluster_name, when set, must start with a letter and use at most 11 letters, digits, or hyphens. hostname plus domain must not exceed 63 characters."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      cluster.license_model == null || contains(["BRING_YOUR_OWN_LICENSE", "LICENSE_INCLUDED"], cluster.license_model)
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].license_model must be BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED when specified."
  }

  validation {
    condition = var.exadb_xs_configuration == null ? true : alltrue([
      for cluster in values(var.exadb_xs_configuration.exadb_vm_clusters) :
      (cluster.scan_listener_port_tcp == null || (cluster.scan_listener_port_tcp >= 1024 && cluster.scan_listener_port_tcp <= 8999)) &&
      length(try(cluster.security.zpr_attributes, [])) <= 3
    ])
    error_message = "exadb_xs_configuration.exadb_vm_clusters[*].scan_listener_port_tcp must be between 1024 and 8999 when specified, and at most three ZPR security attributes are allowed."
  }
}

variable "compartments_dependency" {
  description = "Externally managed compartments keyed by logical name."
  type        = map(object({ id = string }))
  default     = null
}

variable "network_dependency" {
  description = "Externally managed subnets and network security groups keyed by logical name."
  type = object({
    subnets                 = optional(map(object({ id = string })))
    network_security_groups = optional(map(object({ id = string })))
  })
  default = null
}

variable "subscription_dependency" {
  description = "Externally managed subscriptions keyed by logical name."
  type        = map(object({ id = string }))
  default     = null
}

variable "exadata_infrastructure_dependency" {
  description = "Externally managed Cloud Exadata Infrastructures keyed by logical name, for the optional storage-vault exadata_infrastructure_id."
  type = map(object({
    id             = string
    compartment_id = optional(string)
  }))
  default = null
}

variable "exadb_xs_dependency" {
  description = "Externally managed ExaDB-XS and database resources that this module may reference by logical key."
  type = object({
    exascale_db_storage_vaults = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
    exadb_vm_clusters = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
    database_homes = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
    databases           = optional(map(object({ id = string })))
    pluggable_databases = optional(map(object({ id = string })))
  })
  default = null

  validation {
    condition = var.exadb_xs_configuration == null || var.exadb_xs_dependency == null ? true : (
      length(setintersection(toset(keys(var.exadb_xs_configuration.exascale_db_storage_vaults)), toset(keys(coalesce(var.exadb_xs_dependency.exascale_db_storage_vaults, {}))))) == 0 &&
      length(setintersection(toset(keys(var.exadb_xs_configuration.exadb_vm_clusters)), toset(keys(coalesce(var.exadb_xs_dependency.exadb_vm_clusters, {}))))) == 0
    )
    error_message = "exadb_xs_configuration local resource keys must not duplicate keys in exadb_xs_dependency. Use either a local definition or an external dependency for each key."
  }
}

variable "kms_dependency" {
  description = "Externally managed encryption keys passed unchanged to common-database."
  type        = map(any)
  default     = null
}

variable "secrets_dependency" {
  description = "Externally managed OCI Vault secrets passed unchanged to common-database."
  type        = map(object({ id = string }))
  default     = null
}

variable "recovery_service_dependency" {
  description = "Externally managed Autonomous Recovery Service protection policies passed unchanged to common-database."
  type        = any
  default     = null
}

# These three forwarding variables intentionally remain unconstrained so the
# existing common-database public contract is not narrowed or duplicated here.
variable "cloud_db_homes_configuration" {
  description = "DB home configuration forwarded unchanged to ../common-database."
  type        = any
  default     = null
}

variable "databases_configuration" {
  description = "CDB/database configuration forwarded unchanged to ../common-database."
  type        = any
  default     = null
}

variable "pluggable_databases_configuration" {
  description = "PDB configuration forwarded unchanged to ../common-database."
  type        = any
  default     = null
}
