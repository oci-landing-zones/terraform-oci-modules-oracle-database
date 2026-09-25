# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "Name used in the module provenance tag."
  type        = string
  default     = "exascale-db-storage-vault"
}

variable "enable_output" {
  description = "Whether Terraform should return module outputs."
  type        = bool
  default     = true
}

variable "exascale_db_storage_vaults_configuration" {
  description = "Configuration for Exascale DB Storage Vaults. This resource is an OCI Database storage resource, not an OCI Vault/KMS vault."
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
  })
  default = null

  validation {
    condition = var.exascale_db_storage_vaults_configuration == null ? true : alltrue([
      for vault in values(var.exascale_db_storage_vaults_configuration.exascale_db_storage_vaults) :
      vault.exadata_infrastructure_id != null ? (
        vault.high_capacity_database_storage_gbs >= 2000
        ) : (
        vault.high_capacity_database_storage_gbs >= 300 &&
        vault.high_capacity_database_storage_gbs <= 100000
      ) &&
      trimspace(vault.display_name) != "" &&
      (vault.autoscale_limit_in_gbs == null || vault.autoscale_limit_in_gbs >= vault.high_capacity_database_storage_gbs)
    ])
    error_message = "Storage vault display_name must be nonempty. Vaults without exadata_infrastructure_id must set high_capacity_database_storage_gbs between 300 and 100000. Vaults with exadata_infrastructure_id must set at least 2000 GB; their maximum remains Dedicated Infrastructure service-dependent. autoscale_limit_in_gbs, when set, must not be lower than high_capacity_database_storage_gbs."
  }

  validation {
    condition = var.exascale_db_storage_vaults_configuration == null ? true : alltrue([
      for vault in values(var.exascale_db_storage_vaults_configuration.exascale_db_storage_vaults) :
      vault.additional_flash_cache_in_percent == null || (
        vault.additional_flash_cache_in_percent == 0 || (
          vault.additional_flash_cache_in_percent >= 34 &&
          vault.additional_flash_cache_in_percent <= 300
        )
      )
    ])
    error_message = "exascale_db_storage_vaults_configuration.exascale_db_storage_vaults[*].additional_flash_cache_in_percent must be zero (no additional Flash Cache) or between 34 and 300 when specified."
  }
}

variable "compartments_dependency" {
  description = "Externally managed compartments keyed by logical name."
  type        = map(object({ id = string }))
  default     = null
}

variable "subscription_dependency" {
  description = "Externally managed subscriptions keyed by logical name."
  type        = map(object({ id = string }))
  default     = null
}

variable "exadata_infrastructure_dependency" {
  description = "Externally managed Cloud Exadata Infrastructures keyed by logical name. Required only when exadata_infrastructure_id uses a logical key; a literal infrastructure OCID does not require this map."
  type = map(object({
    id             = string
    compartment_id = optional(string)
  }))
  default = null
}
