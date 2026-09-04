# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "common-database"
}

variable "enable_output" {
  description = "Whether Terraform should enable module output."
  type        = bool
  default     = true
}

variable "database_dependency" {
  description = "Externally managed DB homes, databases, and pluggable databases that this module may reference by logical key."
  type = object({
    database_homes = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
    databases = optional(map(object({
      id = string
    })))
    pluggable_databases = optional(map(object({
      id = string
    })))
  })
  default = null
}

variable "vm_cluster_dependency" {
  description = "Externally managed Cloud VM Clusters that DB homes may reference by logical key."
  type = map(object({
    id             = string
    compartment_id = optional(string)
  }))
  default = null
}

variable "db_system_dependency" {
  description = "Externally managed DB Systems that DB homes may reference by logical key."
  type = map(object({
    id             = string
    compartment_id = optional(string)
  }))
  default = null
}

variable "kms_dependency" {
  description = "Externally managed encryption keys that resources may reference by logical key."
  type        = map(any)
  default     = null
}

variable "recovery_service_dependency" {
  description = "Externally managed Autonomous Recovery Service protection policies. Accepts a direct policy map or an object with a protection_policies map."
  type        = any
  default     = null
}

variable "default_defined_tags" {
  description = "Default defined tags for all resources."
  type        = map(string)
  default     = {}
}

variable "default_freeform_tags" {
  description = "Default freeform tags for all resources."
  type        = map(string)
  default     = {}
}

variable "cloud_db_homes_configuration" {
  description = "DB Home Configuration."
  default     = null
  type = map(object({
    # Attributes for oci_database_db_home (from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_db_home)
    database_software_image_id  = optional(string)
    db_system_id                = optional(string)
    db_version                  = optional(string) # e.g., "19.0.0.0"
    defined_tags                = optional(map(string))
    display_name                = optional(string)
    enable_database_delete      = optional(bool, false)
    freeform_tags               = optional(map(string))
    is_desupported_version      = optional(bool)
    is_unified_auditing_enabled = optional(bool)
    kms_key_id                  = optional(string)
    kms_key_version_id          = optional(string)
    source                      = optional(string, "VM_CLUSTER_NEW") # Valid values: "NONE", "DB_BACKUP", "VM_CLUSTER_NEW"
    vm_cluster_id               = optional(string)
    database = optional(map(object({
      admin_password             = string
      backup_id                  = optional(string)
      backup_tde_password        = optional(string)
      character_set              = optional(string)
      database_id                = optional(string)
      database_software_image_id = optional(string)
      db_backup_config = optional(map(object({
        auto_backup_enabled     = optional(bool)
        auto_backup_window      = optional(string)
        auto_full_backup_day    = optional(string)
        auto_full_backup_window = optional(string)
        backup_deletion_policy  = optional(string)
        backup_destination_details = optional(map(object({
          dbrs_policy_id = optional(string)
          id             = optional(string)
          is_remote      = optional(bool)
          remote_region  = optional(string)
          type           = optional(string)
        })))
        recovery_window_in_days   = optional(number)
        run_immediate_full_backup = optional(bool)
      })))
      db_name      = optional(string)
      db_workload  = optional(string)
      defined_tags = optional(map(string))
      encryption_key_location_details = optional(map(object({
        provider_type           = string
        azure_encryption_key_id = optional(string)
        hsm_password            = optional(string)
      })))
      freeform_tags       = optional(map(string))
      key_store_id        = optional(string)
      kms_key_id          = optional(string)
      kms_key_version_id  = optional(string)
      ncharacter_set      = optional(string)
      pdb_name            = optional(string)
      pluggable_databases = optional(list(string))
      sid_prefix          = optional(string)
      source_encryption_key_location_details = optional(map(object({
        provider_type           = string
        azure_encryption_key_id = optional(string)
        hsm_password            = optional(string)
      })))
      tde_wallet_password                   = optional(string)
      time_stamp_for_point_in_time_recovery = optional(string)
      vault_id                              = optional(string)
    })))
  }))
  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        try(length(dv.db_name) <= 8 && can(regex("^[A-Za-z][A-Za-z0-9]*$", dv.db_name)), false)
      ]
    ]))
    error_message = "The legacy inline database name should start with an alphabetical character and have a maximum of 8 characters. Special characters are not permitted."
  }

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        dv.pdb_name == null ? true : (
          length(dv.pdb_name) <= 30 &&
          can(regex("^[A-Za-z][A-Za-z0-9]*$", dv.pdb_name)) &&
          try(upper(dv.pdb_name) != upper(dv.db_name), false)
        )
      ]
    ]))
    error_message = "The legacy inline initial PDB name should start with an alphabetical character, have a maximum of 30 alphanumeric characters, contain no special characters, and differ from the database name."
  }

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        dv.admin_password == null ? true : (
          (can(regex("^[A-Za-z0-9#_-]{9,30}$", dv.admin_password))) &&
          (length(regexall("[A-Z]", dv.admin_password)) >= 2) &&
          (length(regexall("[a-z]", dv.admin_password)) >= 2) &&
          (length(regexall("[0-9]", dv.admin_password)) >= 2) &&
          (length(regexall("[#_-]", dv.admin_password)) >= 2)
        )
      ]
    ]))
    error_message = "The admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        dv.tde_wallet_password == null ? true : (
          (can(regex("^[A-Za-z0-9#_-]{9,30}$", dv.tde_wallet_password))) &&
          (length(regexall("[A-Z]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[a-z]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[0-9]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[#_-]", dv.tde_wallet_password)) >= 2)
        )
      ]
    ]))
    error_message = "The tde wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

}

variable "databases_configuration" {
  description = "Database Configuration."
  default     = null
  type = map(object({
    database = object({
      admin_password             = string #sensitive
      db_name                    = string
      backup_id                  = optional(string) # For restore
      backup_tde_password        = optional(string)
      character_set              = optional(string)
      database_admin_password    = optional(string) # For when source=DATAGUARD
      database_id                = optional(string)
      database_software_image_id = optional(string)
      db_backup_config = optional(object({
        auto_backup_enabled     = optional(bool)
        auto_backup_window      = optional(string)
        auto_full_backup_day    = optional(string)
        auto_full_backup_window = optional(string)
        backup_deletion_policy  = optional(string)
        backup_destination_details = optional(object({
          dbrs_policy_id = optional(string)
          id             = optional(string)
          is_remote      = optional(bool)
          remote_region  = optional(string)
          type           = optional(string)
          vpc_password   = optional(string)
          vpc_user       = optional(string)
        }))
        recovery_window_in_days   = optional(number)
        run_immediate_full_backup = optional(bool)
      }))
      db_unique_name = optional(string)
      db_workload    = optional(string) # e.g., "OLTP"
      defined_tags   = optional(map(string))
      encryption_key_location_details = optional(object({
        provider_type           = string
        azure_encryption_key_id = optional(string)
        hsm_password            = optional(string)
      }))
      freeform_tags                          = optional(map(string))
      key_store_id                           = optional(string)
      is_active_data_guard_enabled           = optional(bool)
      kms_key_id                             = optional(string)
      kms_key_version_id                     = optional(string)
      ncharacter_set                         = optional(string)
      pdb_name                               = optional(string)
      pluggable_databases                    = optional(list(string))
      protection_mode                        = optional(string)
      sid_prefix                             = optional(string)
      source_database_id                     = optional(string)
      source_tde_wallet_password             = optional(string)
      source_encryption_key_location_details = optional(map(string)) # Supported keys: provider_type, hsm_password
      tde_wallet_password                    = optional(string)
      time_stamp_for_point_in_time_recovery  = optional(string)
      transport_type                         = optional(string)
      vault_id                               = optional(string)
    })
    db_home_id         = string
    source             = string
    key_store_id       = optional(string)
    db_version         = optional(string)
    kms_key_id         = optional(string)
    kms_key_version_id = optional(string)
  }))
  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      (length(v.database.db_name) <= 8 && can(regex("^[A-Za-z][A-Za-z0-9]*$", v.database.db_name)))
    ])
    error_message = "The database name should start with an alphabetical character and have a maximum of 8 characters. Special characters are not permitted."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      contains(["NONE", "DB_BACKUP", "DATAGUARD"], v.source)
    ])
    error_message = "Invalid database source. Accepted values are NONE, DB_BACKUP, and DATAGUARD."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.source != "DB_BACKUP" ? true : try(length(trimspace(v.database.backup_id)) > 0, false)
    ])
    error_message = "backup_id is required when database source is DB_BACKUP."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.database.pdb_name == null ? true : (
        length(v.database.pdb_name) <= 30 &&
        can(regex("^[A-Za-z][A-Za-z0-9]*$", v.database.pdb_name)) &&
        upper(v.database.pdb_name) != upper(v.database.db_name)
      )
    ])
    error_message = "The initial PDB name should start with an alphabetical character, have a maximum of 30 alphanumeric characters, contain no special characters, and differ from the database name."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.source != "DATAGUARD" ? true : (
        try(length(trimspace(v.database.database_admin_password)) > 0, false) &&
        try(length(trimspace(v.database.protection_mode)) > 0, false) &&
        try(length(trimspace(v.database.source_database_id)) > 0, false) &&
        try(length(trimspace(v.database.source_tde_wallet_password)) > 0, false) &&
        try(length(trimspace(v.database.transport_type)) > 0, false)
      )
    ])
    error_message = "database_admin_password, protection_mode, source_database_id, source_tde_wallet_password, and transport_type are required when database source is DATAGUARD."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.source != "DATAGUARD" ? true : try(contains(["MAXIMUM_AVAILABILITY", "MAXIMUM_PERFORMANCE", "MAXIMUM_PROTECTION"], v.database.protection_mode), false)
    ])
    error_message = "Invalid Data Guard protection_mode. Accepted values are MAXIMUM_AVAILABILITY, MAXIMUM_PERFORMANCE, and MAXIMUM_PROTECTION."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.source != "DATAGUARD" ? true : try(v.database.transport_type == "ASYNC", false)
    ])
    error_message = "Invalid Data Guard transport_type. OCI Database currently supports ASYNC for this module contract."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.database.source_encryption_key_location_details == null ? true : (
        contains(keys(v.database.source_encryption_key_location_details), "provider_type") &&
        alltrue([
          for detail_key in keys(v.database.source_encryption_key_location_details) :
          contains(["provider_type", "hsm_password"], detail_key)
        ])
      )
    ])
    error_message = "source_encryption_key_location_details supports only provider_type and hsm_password. provider_type is required."
  }
  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      try(v.database.db_backup_config.backup_destination_details.type, null) == null ? true : contains(["AWS_S3", "DBRS", "OBJECT_STORE", "NFS", "RECOVERY_APPLIANCE", "LOCAL"], v.database.db_backup_config.backup_destination_details.type)
    ])
    error_message = "Invalid backup destination type. Accepted values are AWS_S3, DBRS, OBJECT_STORE, NFS, RECOVERY_APPLIANCE, and LOCAL."
  }
  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.database.admin_password == null ? true : (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.database.admin_password))) &&
        (length(regexall("[A-Z]", v.database.admin_password)) >= 2) &&
        (length(regexall("[a-z]", v.database.admin_password)) >= 2) &&
        (length(regexall("[0-9]", v.database.admin_password)) >= 2) &&
        (length(regexall("[#_-]", v.database.admin_password)) >= 2)
      )
    ])
    error_message = "The admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.database.tde_wallet_password == null ? true : (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.database.tde_wallet_password))) &&
        (length(regexall("[A-Z]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[a-z]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[0-9]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[#_-]", v.database.tde_wallet_password)) >= 2)
      )
    ])
    error_message = "The tde wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }
}

variable "pluggable_databases_configuration" {
  description = "Pluggable Database Configuration."
  default     = null
  type = map(object({
    container_database_id = string # Literal OCID, local database key, or database_dependency key
    pdb_name              = string

    container_database_admin_password = optional(string) # Sensitive
    defined_tags                      = optional(map(string))
    freeform_tags                     = optional(map(string))
    kms_key_version_id                = optional(string)
    pdb_admin_password                = optional(string) # Sensitive
    pdb_creation_type_details = optional(object({
      creation_type                = string
      source_pluggable_database_id = string
      dblink_user_password         = optional(string)
      dblink_username              = optional(string)
      is_thin_clone                = optional(bool)
      refreshable_clone_details = optional(object({
        is_refreshable_clone = optional(bool)
      }))
      source_container_database_admin_password = optional(string) # Sensitive
    }))
    should_create_pdb_backup           = optional(bool)
    should_pdb_admin_account_be_locked = optional(bool)
    tde_wallet_password                = optional(string)
  }))
  validation {
    condition = var.pluggable_databases_configuration == null ? true : alltrue([
      for k, v in var.pluggable_databases_configuration :
      (length(v.pdb_name) <= 30 && can(regex("^[A-Za-z][A-Za-z0-9]*$", v.pdb_name)))
    ])
    error_message = "The PDB name should start with an alphabetical character and have a maximum of 30 alphanumeric characters. Special characters are not permitted."
  }

  validation {
    condition = var.pluggable_databases_configuration == null ? true : alltrue([
      for k, v in var.pluggable_databases_configuration :
      v.pdb_admin_password == null ? true : (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.pdb_admin_password))) &&
        (length(regexall("[A-Z]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[a-z]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[0-9]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[#_-]", v.pdb_admin_password)) >= 2)
      )
    ])
    error_message = "The pdb admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.pluggable_databases_configuration == null ? true : alltrue([
      for k, v in var.pluggable_databases_configuration :
      v.tde_wallet_password == null ? true : (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.tde_wallet_password))) &&
        (length(regexall("[A-Z]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[a-z]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[0-9]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[#_-]", v.tde_wallet_password)) >= 2)
      )
    ])
    error_message = "The tde wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }
}
