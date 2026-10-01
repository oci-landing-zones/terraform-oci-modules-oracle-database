# Copyright (c) 2023, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {
  description = "The tenancy OCID used to look up Availability Domains and Oracle-managed Recovery Service policies."
  type        = string
}

variable "db_systems_configuration" {
  description = "Base Database Service DB systems to manage. Compartment, subnet, NSG, and KMS values accept an OCID or a key from the matching dependency input."
  type = object({
    default_compartment_id = optional(string)
    default_subnet_id      = optional(string)
    default_defined_tags   = optional(map(string))
    default_freeform_tags  = optional(map(string))

    db_systems = optional(map(object({
      display_name       = string
      ssh_public_keys    = list(string)
      hostname           = optional(string)
      subnet_id          = optional(string)
      compartment_id     = optional(string)
      nsg_ids            = optional(list(string), [])
      kms_key_id         = optional(string)
      kms_key_version_id = optional(string)
      placement = optional(object({
        availability_domain = optional(number, 1)
        fault_domains       = optional(list(number), [1])
      }))
      db_system_options = optional(object({
        storage_management = optional(string, "ASM")
      }), {})
      shape                           = optional(string, "VM.Standard.E5.Flex")
      cpu_core_count                  = optional(number, 1)
      database_edition                = optional(string, "ENTERPRISE_EDITION")
      license_model                   = optional(string, "BRING_YOUR_OWN_LICENSE")
      data_storage_size_in_gb         = optional(number, 256)
      storage_volume_performance_mode = optional(string, "HIGH_PERFORMANCE")
      time_zone                       = optional(string, "UTC")
      defined_tags                    = optional(map(string))
      freeform_tags                   = optional(map(string))
      db_home = object({
        display_name                = optional(string)
        database_software_image_id  = optional(string)
        is_unified_auditing_enabled = optional(bool, false)
        database = object({
          db_name                               = string
          admin_password                        = optional(string)
          admin_password_secret_id              = optional(string)
          db_version                            = string
          database_software_image_id            = optional(string)
          character_set                         = optional(string, "AL32UTF8")
          ncharacter_set                        = optional(string, "AL16UTF16")
          db_workload                           = optional(string, null)
          pdb_name                              = optional(string)
          backup_id                             = optional(string)
          backup_tde_password                   = optional(string)
          tde_wallet_password                   = optional(string)
          time_stamp_for_point_in_time_recovery = optional(string)
          additional_pdbs = optional(map(object({
            pdb_name                     = string
            pdb_admin_password           = optional(string)
            pdb_admin_password_secret_id = optional(string)
            defined_tags                 = optional(map(string))
            freeform_tags                = optional(map(string))
          })), {})
          db_backup_config = optional(object({
            auto_backup_enabled     = optional(bool, false)
            auto_backup_window      = optional(string)
            auto_full_backup_day    = optional(string)
            auto_full_backup_window = optional(string)
            backup_deletion_policy  = optional(string)
            backup_destination_details = optional(object({
              backup_retention_policy_on_terminate = optional(string)
              dbrs_policy_id                       = optional(string)
              id                                   = optional(string)
              is_remote                            = optional(bool)
              is_retention_lock_enabled            = optional(bool)
              remote_region                        = optional(string)
              type                                 = optional(string)
            }))
            recovery_window_in_days   = optional(number)
            run_immediate_full_backup = optional(bool)
          }), {})
        })
      })
    })), {})
  })
  default = null

  validation {
    condition     = var.db_systems_configuration == null || length(coalesce(var.db_systems_configuration.db_systems, {})) > 0
    error_message = "db_systems_configuration.db_systems must contain at least one DB System when db_systems_configuration is provided."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      (try(length(db_system.db_home.database.admin_password) > 0, false)) !=
      (try(length(trimspace(db_system.db_home.database.admin_password_secret_id)) > 0, false))
    ])
    error_message = "Each DB System must define exactly one of admin_password or admin_password_secret_id."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      try(length(db_system.db_home.database.db_name) <= 8 && can(regex("^[A-Za-z][A-Za-z0-9]*$", db_system.db_home.database.db_name)), false)
    ])
    error_message = "The database name should start with an alphabetical character and have a maximum of 8 characters. Special characters are not permitted."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      db_system.db_home.database.pdb_name == null ? true : (
        length(db_system.db_home.database.pdb_name) <= 30 &&
        can(regex("^[A-Za-z][A-Za-z0-9]*$", db_system.db_home.database.pdb_name)) &&
        try(upper(db_system.db_home.database.pdb_name) != upper(db_system.db_home.database.db_name), false)
      )
    ])
    error_message = "The initial PDB name should start with an alphabetical character, have a maximum of 30 alphanumeric characters, contain no special characters, and differ from the database name."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : alltrue([
        for pdb in values(try(db_system.db_home.database.additional_pdbs, {})) : (
          length(pdb.pdb_name) <= 30 &&
          can(regex("^[A-Za-z][A-Za-z0-9]*$", pdb.pdb_name)) &&
          upper(pdb.pdb_name) != upper(db_system.db_home.database.db_name) &&
          (db_system.db_home.database.pdb_name == null || upper(pdb.pdb_name) != upper(db_system.db_home.database.pdb_name))
        )
      ])
    ])
    error_message = "Additional PDB names must start with a letter, contain only alphanumeric characters, be at most 30 characters, and differ from the database and inline PDB names."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        length(distinct([for pdb in values(try(db_system.db_home.database.additional_pdbs, {})) : upper(pdb.pdb_name)])) == length(values(try(db_system.db_home.database.additional_pdbs, {})))
      )
    ])
    error_message = "Additional PDB names must be unique within each DB System."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for db_system in coalesce(var.db_systems_configuration.db_systems, {}) : alltrue([
        for pdb in values(try(db_system.db_home.database.additional_pdbs, {})) :
        (try(length(pdb.pdb_admin_password) > 0, false)) !=
        (try(length(trimspace(pdb.pdb_admin_password_secret_id)) > 0, false))
      ])
    ])
    error_message = "Each additional PDB must provide exactly one of pdb_admin_password or pdb_admin_password_secret_id."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for db_system in coalesce(var.db_systems_configuration.db_systems, {}) : alltrue([
        for pdb in values(try(db_system.db_home.database.additional_pdbs, {})) :
        try(length(pdb.pdb_admin_password) > 0, false) ? (
          can(regex("^[A-Za-z0-9#_-]{9,30}$", pdb.pdb_admin_password)) &&
          length(regexall("[A-Z]", pdb.pdb_admin_password)) >= 2 &&
          length(regexall("[a-z]", pdb.pdb_admin_password)) >= 2 &&
          length(regexall("[0-9]", pdb.pdb_admin_password)) >= 2 &&
          length(regexall("[#_-]", pdb.pdb_admin_password)) >= 2
        ) : true
      ])
    ])
    error_message = "Each additional PDB pdb_admin_password must be 9-30 characters and contain at least two uppercase letters, lowercase letters, numbers, and special characters (#, _, -)."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      db_system.db_home.database.admin_password == null || (
        can(regex("^[A-Za-z0-9#_-]{9,30}$", db_system.db_home.database.admin_password)) &&
        length(regexall("[A-Z]", db_system.db_home.database.admin_password)) >= 2 &&
        length(regexall("[a-z]", db_system.db_home.database.admin_password)) >= 2 &&
        length(regexall("[0-9]", db_system.db_home.database.admin_password)) >= 2 &&
        length(regexall("[#_-]", db_system.db_home.database.admin_password)) >= 2
      )
    ])
    error_message = "Each admin_password must be 9-30 characters and contain at least two uppercase letters, lowercase letters, numbers, and special characters (#, _, -)."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      try(db_system.placement.availability_domain, 1) >= 1
    ])
    error_message = "placement.availability_domain must be greater than or equal to 1."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      db_system.compartment_id != null || var.db_systems_configuration.default_compartment_id != null
    ])
    error_message = "Each DB System must set compartment_id or db_systems_configuration.default_compartment_id."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      db_system.subnet_id != null || var.db_systems_configuration.default_subnet_id != null
    ])
    error_message = "Each DB System must set subnet_id or db_systems_configuration.default_subnet_id."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) :
      try(db_system.db_home.database.db_backup_config.backup_destination_details, null) == null || contains([
        "AWS_S3", "DBRS", "LOCAL", "NFS", "OBJECT_STORE", "RECOVERY_APPLIANCE"
      ], try(db_system.db_home.database.db_backup_config.backup_destination_details.type, null))
    ])
    error_message = "backup_destination_details.type is required and must be a supported backup destination type."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        try(db_system.db_home.database.db_backup_config.backup_destination_details.type, null) == "DBRS" ?
        try(trimspace(db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id) != "", false) :
        try(db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id, null) == null
      )
    ])
    error_message = "backup_destination_details.type = DBRS requires a non-empty dbrs_policy_id reference; dbrs_policy_id must be omitted for other destination types."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : contains(["ASM", "LVM"], db_system.db_system_options.storage_management)
    ])
    error_message = "storage_management must be ASM or LVM."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : contains(["BALANCED", "HIGH_PERFORMANCE"], db_system.storage_volume_performance_mode)
    ])
    error_message = "storage_volume_performance_mode must be BALANCED or HIGH_PERFORMANCE."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : contains(["BRING_YOUR_OWN_LICENSE", "LICENSE_INCLUDED"], db_system.license_model)
    ])
    error_message = "license_model must be BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : db_system.db_home.database.ncharacter_set == null || contains(["AL16UTF16", "UTF8"], db_system.db_home.database.ncharacter_set)
    ])
    error_message = "ncharacter_set must be AL16UTF16 or UTF8."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        db_system.db_home.database.db_backup_config.auto_backup_window == null || contains([
          "SLOT_ONE", "SLOT_TWO", "SLOT_THREE", "SLOT_FOUR", "SLOT_FIVE", "SLOT_SIX",
          "SLOT_SEVEN", "SLOT_EIGHT", "SLOT_NINE", "SLOT_TEN", "SLOT_ELEVEN", "SLOT_TWELVE"
        ], db_system.db_home.database.db_backup_config.auto_backup_window)
      )
    ])
    error_message = "auto_backup_window must be SLOT_ONE through SLOT_TWELVE."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        db_system.db_home.database.db_backup_config.auto_full_backup_window == null || contains([
          "SLOT_ONE", "SLOT_TWO", "SLOT_THREE", "SLOT_FOUR", "SLOT_FIVE", "SLOT_SIX",
          "SLOT_SEVEN", "SLOT_EIGHT", "SLOT_NINE", "SLOT_TEN", "SLOT_ELEVEN", "SLOT_TWELVE"
        ], db_system.db_home.database.db_backup_config.auto_full_backup_window)
      )
    ])
    error_message = "auto_full_backup_window must be SLOT_ONE through SLOT_TWELVE."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        db_system.db_home.database.db_backup_config.auto_full_backup_day == null || contains([
          "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
        ], db_system.db_home.database.db_backup_config.auto_full_backup_day)
      )
    ])
    error_message = "auto_full_backup_day must be a day from MONDAY through SUNDAY."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        db_system.db_home.database.db_backup_config.backup_deletion_policy == null || contains([
          "DELETE_IMMEDIATELY", "DELETE_AFTER_RETENTION_PERIOD"
        ], db_system.db_home.database.db_backup_config.backup_deletion_policy)
      )
    ])
    error_message = "backup_deletion_policy must be DELETE_IMMEDIATELY or DELETE_AFTER_RETENTION_PERIOD."
  }

  validation {
    condition = var.db_systems_configuration == null ? true : alltrue([
      for key, db_system in coalesce(var.db_systems_configuration.db_systems, {}) : (
        try(db_system.db_home.database.db_backup_config.backup_destination_details.backup_retention_policy_on_terminate, null) == null || contains([
          "RETAIN_PER_RETENTION_WINDOW", "RETAIN_FOR_72_HOURS"
        ], db_system.db_home.database.db_backup_config.backup_destination_details.backup_retention_policy_on_terminate)
      )
    ])
    error_message = "backup_retention_policy_on_terminate must be RETAIN_PER_RETENTION_WINDOW or RETAIN_FOR_72_HOURS."
  }

}

variable "compartments_dependency" {
  description = "A map of objects containing the externally managed compartments this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the compartment OCID) of string type."
  type = map(object({
    id = string # the compartment OCID
  }))
  default = null
}

variable "network_dependency" {
  description = "An object containing the externally managed subnets and network security groups this module may depend on. Each object, when defined, must have an 'id' attribute of string type."
  type = object({
    subnets = optional(map(object({
      id = string # the subnet OCID
    })))
    network_security_groups = optional(map(object({
      id = string # the NSG OCID
    })))
  })
  default = null
}

variable "kms_dependency" {
  description = "A map of objects containing the externally managed encryption keys this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the key OCID) of string type."
  type = map(object({
    id = string # the key OCID.
  }))
  default = null
}

variable "secrets_dependency" {
  description = "Vault secrets indexed by logical dependency key."
  type = map(object({
    id = string
  }))
  default = null
}

variable "recovery_service_dependency" {
  type    = any
  default = null
}

variable "enable_output" {
  description = "Whether Terraform should enable module outputs."
  type        = bool
  default     = true
}

variable "module_name" {
  description = "Module name used in the freeform module tag."
  type        = string
  default     = "base_database"
}
