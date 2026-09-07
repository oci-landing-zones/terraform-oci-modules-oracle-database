# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ------------------------------------------------------
# ----- General
#-------------------------------------------------------

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "exadata-cloud-service"
}

variable "enable_output" {
  description = "Whether Terraform should enable module output."
  type        = bool
  default     = true
}

variable "compartments_dependency" {
  description = "A map of objects containing the externally managed compartments this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute of string type set with the compartment OCID."
  type        = map(any)
  default     = null
}

variable "subscription_dependency" {
  description = "A map of objects containing the externally managed subscriptions  this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute of string type set with the subscription OCID."
  type        = map(any)
  default     = null
}

variable "exadata_database_dependency" {
  description = "A map of objects containing externally managed Exadata Database resources this module may depend on. All map objects must contain at least an 'id' attribute of string type set with the resource OCID."
  type = object({
    cloud_exadata_infrastructures = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
    cloud_vm_clusters = optional(map(object({
      id             = string
      compartment_id = optional(string)
    })))
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

variable "kms_dependency" {
  description = "A map of objects containing externally managed encryption keys this module may depend on. All map objects must contain at least an 'id' attribute of string type set with the key OCID."
  type        = map(any)
  default     = null
}

variable "network_dependency" {
  description = "A map of objects containing the externally managed network resources (e.g., subnets, NSGs) this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute of string type set with the resource OCID."
  type = object({
    subnets = optional(map(object({
      id = string # the subnet OCID
    })))
    network_security_groups = optional(map(object({
      id = string # the subnet OCID
    })))
  })
  default = null
}

variable "recovery_service_dependency" {
  description = "A map of objects containing externally managed Autonomous Recovery Service resources this module may depend on. Use either a direct protection policy map, or an object with a protection_policies map. Each protection policy object must contain at least an 'id' attribute with the protection policy OCID."
  type        = any
  default     = null
}

variable "secrets_dependency" {
  description = "A map of objects containing externally managed OCI secrets this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the secret OCID) of string type."
  type = map(object({
    id = string
  }))
  default = null
}

variable "default_compartment_id" {
  description = "Default compartment OCID, tenancy OCID for the root compartment, or compartments_dependency key for all resources."
  type        = string
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

variable "cloud_exadata_infrastructures_configuration" {
  description = "Exadata infrastructure configuration."
  default     = null
  type = object({
    default_maintenance_window = optional(object({
      custom_action_timeout_in_mins    = optional(number)
      is_custom_action_timeout_enabled = optional(bool)
      is_monthly_patching_enabled      = optional(bool)
      patching_mode                    = optional(string)
      preference                       = optional(string, "NO_PREFERENCE") # e.g., "NO_PREFERENCE"
      months                           = optional(list(string))
      weeks_of_month                   = optional(list(number))
      days_of_week                     = optional(list(string))
      # The window of hours during the day when maintenance should be performed. The window is a 4 hour slot. 
      # Valid values are 0 - represents time slot 0:00 - 3:59 UTC - 4 - represents time slot 4:00 - 7:59 UTC - 
      # 8 - represents time slot 8:00 - 11:59 UTC - 12 - represents time slot 12:00 - 15:59 UTC - 
      # 16 - represents time slot 16:00 - 19:59 UTC - 20 - represents time slot 20:00 - 23:59 UTC
      hours_of_day       = optional(list(number))
      lead_time_in_weeks = optional(number)
    }))

    cloud_exadata_infrastructures = map(object({
      # Attributes for oci_database_cloud_exadata_infrastructure (from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_cloud_exadata_infrastructure)
      display_name        = string
      shape               = string           # Possible values: Exadata.X11MV, Exadata.X11M, Exadata.X9M, Exadata.X8M
      compartment_id      = optional(string) # Overrides default; compartment/tenancy OCID or key in compartments_dependency
      availability_domain = optional(string) # Defaults to the lexicographically first discovered AD.

      compute_count = optional(number)
      customer_contacts = optional(object({
        email = optional(string)
      }))

      # source: https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/exadata/doc/ecc-manage-infrastructure.html#Compute%20and%20storage%20configuration
      database_server_type = optional(string) # Possible values: X11MV, X11M-BASE, X11M, X11M-L, and X11M-XL
      defined_tags         = optional(map(string))
      freeform_tags        = optional(map(string))

      maintenance_window = optional(object({
        custom_action_timeout_in_mins    = optional(number)
        days_of_week                     = optional(list(string))
        hours_of_day                     = optional(list(number))
        is_custom_action_timeout_enabled = optional(bool)
        is_monthly_patching_enabled      = optional(bool)
        lead_time_in_weeks               = optional(number)

        months         = optional(list(string))
        patching_mode  = optional(string)
        preference     = optional(string, "NO_PREFERENCE") # e.g., "NO_PREFERENCE"
        weeks_of_month = optional(list(number))
      }))
      storage_count       = optional(number)
      storage_server_type = optional(string) # X11MV-HC, X11M-BASE, and X11M-HC
      subscription_id     = optional(string)
    }))
  })

  validation {
    condition = var.cloud_exadata_infrastructures_configuration == null ? true : alltrue([
      for k, v in var.cloud_exadata_infrastructures_configuration.cloud_exadata_infrastructures :
      contains(["Exadata.X11MV", "Exadata.X11M", "Exadata.X9M", "Exadata.X8M"], v.shape)
    ])
    error_message = "Invalid shape, accepted values are Exadata.X11MV, Exadata.X11M, Exadata.X9M, and Exadata.X8M."
  }

  validation {
    condition = var.cloud_exadata_infrastructures_configuration == null ? true : alltrue([
      for k, v in var.cloud_exadata_infrastructures_configuration.cloud_exadata_infrastructures :
      (v.database_server_type == null || contains(["X11MV", "X11M-BASE", "X11M", "X11M-L", "X11M-XL"], v.database_server_type))
    ])
    error_message = "Invalid database server type, accepted values are X11MV, X11M-BASE, X11M, X11M-L, and X11M-XL."
  }

  validation {
    condition = var.cloud_exadata_infrastructures_configuration == null ? true : alltrue([
      for k, v in var.cloud_exadata_infrastructures_configuration.cloud_exadata_infrastructures :
      (v.storage_server_type == null || contains(["X11MV-HC", "X11M-BASE", "X11M-HC"], v.storage_server_type))
    ])
    error_message = "Invalid storage server type, accepted values are X11MV-HC, X11M-BASE, and X11M-HC."
  }
}

variable "cloud_vm_clusters_configuration" {
  description = "OCI Database Cloud VM Cluster Configuration."
  default     = null
  type = map(object({
    # Attributes for oci_database_cloud_vm_cluster (from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_cloud_vm_cluster)
    backup_subnet_id = string # Literal OCID or key in network_dependency

    exadata_infrastructure_id = optional(string) # OCID or key of the database cloud exadata infrastructure.
    compartment_id            = optional(string) # Overrides default; compartment/tenancy OCID or key in compartments_dependency
    cpu_core_count            = number
    display_name              = string
    gi_version                = string # e.g., "19.0.0.0"
    hostname                  = string
    ssh_public_keys           = list(string)
    subnet_id                 = string # Literal OCID or key in network_dependency

    backup_network_nsg_ids = optional(list(string)) # Literal OCIDs or keys in network_dependency
    cloud_automation_update_details = optional(object({
      apply_update_time_preference = optional(object({
        apply_update_preferred_end_time   = optional(string)
        apply_update_preferred_start_time = optional(string)
      }))
      freeze_period = optional(object({
        freeze_period_end_time   = optional(string)
        freeze_period_start_time = optional(string)
      }))
      is_early_adoption_enabled = optional(bool)
      is_freeze_period_enabled  = optional(bool)
    }))

    cluster_name = optional(string)
    data_collection_options = optional(object({
      is_diagnostics_events_enabled = optional(bool)
      is_health_monitoring_enabled  = optional(bool)
      is_incident_logs_enabled      = optional(bool)
    }))
    data_storage_percentage     = optional(number) #. Accepted values are 35, 40, 60 and 80. 
    data_storage_size_in_tbs    = optional(number)
    db_node_storage_size_in_gbs = optional(number)
    db_servers                  = optional(list(string))
    defined_tags                = optional(map(string))
    freeform_tags               = optional(map(string))
    domain                      = optional(string)
    file_system_configuration_details = optional(map(object({
      file_system_size_gb = optional(number)
      mount_point         = optional(string)
    })))
    is_local_backup_enabled     = optional(bool, false)
    is_sparse_diskgroup_enabled = optional(bool, false)
    license_model               = optional(string)
    memory_size_in_gbs          = optional(number)
    nsg_ids                     = optional(list(string))
    ocpu_count                  = optional(number)
    private_zone_id             = optional(string)
    scan_listener_port_tcp      = optional(number)
    scan_listener_port_tcp_ssl  = optional(number)
    security = optional(object({ ## security_attributes
      zpr_attributes = optional(list(object({
        namespace  = optional(string, "oracle-zpr")
        attr_name  = string
        attr_value = string
        mode       = optional(string, "enforce")
      })))
    }))
    subscription_id = optional(string)
    system_version  = optional(string)
    time_zone       = optional(string)
    vm_cluster_type = optional(string)
  }))
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
      admin_password                = optional(string)
      admin_password_secret_id      = optional(string)
      backup_id                     = optional(string)
      backup_tde_password           = optional(string)
      backup_tde_password_secret_id = optional(string)
      character_set                 = optional(string)
      database_id                   = optional(string)
      database_software_image_id    = optional(string)
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
        hsm_password_secret_id  = optional(string)
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
      tde_wallet_password_secret_id         = optional(string)
      time_stamp_for_point_in_time_recovery = optional(string)
      vault_id                              = optional(string)
    })))
  }))
  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        try(length(dv.admin_password) > 0, false) != try(length(trimspace(dv.admin_password_secret_id)) > 0, false)
      ]
    ]))
    error_message = "Each legacy inline database must define exactly one of admin_password or admin_password_secret_id."
  }

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration : [
        for dk, dv in coalesce(v.database, {}) : concat([
          !(try(length(dv.backup_tde_password) > 0, false) && try(length(trimspace(dv.backup_tde_password_secret_id)) > 0, false)),
          !(try(length(dv.tde_wallet_password) > 0, false) && try(length(trimspace(dv.tde_wallet_password_secret_id)) > 0, false))
          ], [
          for detail in values(coalesce(dv.encryption_key_location_details, {})) :
          !(try(length(detail.hsm_password) > 0, false) && try(length(trimspace(detail.hsm_password_secret_id)) > 0, false))
        ])
      ]
    ]))
    error_message = "Each optional legacy inline database password must define at most one of its literal value or corresponding secret_id."
  }

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
        try(length(dv.admin_password) > 0, false) ? (
          (can(regex("^[A-Za-z0-9#_-]{9,30}$", dv.admin_password))) &&
          (length(regexall("[A-Z]", dv.admin_password)) >= 2) &&
          (length(regexall("[a-z]", dv.admin_password)) >= 2) &&
          (length(regexall("[0-9]", dv.admin_password)) >= 2) &&
          (length(regexall("[#_-]", dv.admin_password)) >= 2)
        ) : true
      ]
    ]))
    error_message = "The admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : alltrue(flatten([
      for k, v in var.cloud_db_homes_configuration :
      [for dk, dv in coalesce(v.database, {}) :
        try(length(dv.tde_wallet_password) > 0, false) ? (
          (can(regex("^[A-Za-z0-9#_-]{9,30}$", dv.tde_wallet_password))) &&
          (length(regexall("[A-Z]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[a-z]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[0-9]", dv.tde_wallet_password)) >= 2) &&
          (length(regexall("[#_-]", dv.tde_wallet_password)) >= 2)
        ) : true
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
      admin_password                    = optional(string) # sensitive
      admin_password_secret_id          = optional(string)
      db_name                           = string
      backup_id                         = optional(string) # For restore
      backup_tde_password               = optional(string)
      backup_tde_password_secret_id     = optional(string)
      character_set                     = optional(string)
      database_admin_password           = optional(string) # For when source=DATAGUARD
      database_admin_password_secret_id = optional(string)
      database_id                       = optional(string)
      database_software_image_id        = optional(string)
      db_backup_config = optional(object({
        auto_backup_enabled     = optional(bool)
        auto_backup_window      = optional(string)
        auto_full_backup_day    = optional(string)
        auto_full_backup_window = optional(string)
        backup_deletion_policy  = optional(string)
        backup_destination_details = optional(object({
          dbrs_policy_id         = optional(string)
          id                     = optional(string)
          is_remote              = optional(bool)
          remote_region          = optional(string)
          type                   = optional(string)
          vpc_password           = optional(string)
          vpc_password_secret_id = optional(string)
          vpc_user               = optional(string)
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
        hsm_password_secret_id  = optional(string)
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
      source_tde_wallet_password_secret_id   = optional(string)
      source_encryption_key_location_details = optional(map(string)) # Supported keys: provider_type, hsm_password, hsm_password_secret_id
      tde_wallet_password                    = optional(string)
      tde_wallet_password_secret_id          = optional(string)
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
      try(length(v.database.admin_password) > 0, false) != try(length(trimspace(v.database.admin_password_secret_id)) > 0, false)
    ])
    error_message = "Each database must define exactly one of admin_password or admin_password_secret_id."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue(flatten([
      for k, v in var.databases_configuration : [
        !(try(length(v.database.backup_tde_password) > 0, false) && try(length(trimspace(v.database.backup_tde_password_secret_id)) > 0, false)),
        !(try(length(v.database.database_admin_password) > 0, false) && try(length(trimspace(v.database.database_admin_password_secret_id)) > 0, false)),
        !(try(length(v.database.db_backup_config.backup_destination_details.vpc_password) > 0, false) && try(length(trimspace(v.database.db_backup_config.backup_destination_details.vpc_password_secret_id)) > 0, false)),
        !(try(length(v.database.encryption_key_location_details.hsm_password) > 0, false) && try(length(trimspace(v.database.encryption_key_location_details.hsm_password_secret_id)) > 0, false)),
        !(try(length(v.database.source_tde_wallet_password) > 0, false) && try(length(trimspace(v.database.source_tde_wallet_password_secret_id)) > 0, false)),
        !(try(length(v.database.source_encryption_key_location_details["hsm_password"]) > 0, false) && try(length(trimspace(v.database.source_encryption_key_location_details["hsm_password_secret_id"])) > 0, false)),
        !(try(length(v.database.tde_wallet_password) > 0, false) && try(length(trimspace(v.database.tde_wallet_password_secret_id)) > 0, false))
      ]
    ]))
    error_message = "Each optional database password must define at most one of its literal value or corresponding secret_id."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      v.source != "DATAGUARD" ? true : (
        (try(length(v.database.database_admin_password) > 0, false) != try(length(trimspace(v.database.database_admin_password_secret_id)) > 0, false)) &&
        try(length(trimspace(v.database.protection_mode)) > 0, false) &&
        try(length(trimspace(v.database.source_database_id)) > 0, false) &&
        (try(length(v.database.source_tde_wallet_password) > 0, false) != try(length(trimspace(v.database.source_tde_wallet_password_secret_id)) > 0, false)) &&
        try(length(trimspace(v.database.transport_type)) > 0, false)
      )
    ])
    error_message = "A database_admin_password value or secret reference, protection_mode, source_database_id, a source_tde_wallet_password value or secret reference, and transport_type are required when database source is DATAGUARD."
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
          contains(["provider_type", "hsm_password", "hsm_password_secret_id"], detail_key)
        ])
      )
    ])
    error_message = "source_encryption_key_location_details supports only provider_type, hsm_password, and hsm_password_secret_id. provider_type is required."
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
      try(length(v.database.admin_password) > 0, false) ? (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.database.admin_password))) &&
        (length(regexall("[A-Z]", v.database.admin_password)) >= 2) &&
        (length(regexall("[a-z]", v.database.admin_password)) >= 2) &&
        (length(regexall("[0-9]", v.database.admin_password)) >= 2) &&
        (length(regexall("[#_-]", v.database.admin_password)) >= 2)
      ) : true
    ])
    error_message = "The admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.databases_configuration == null ? true : alltrue([
      for k, v in var.databases_configuration :
      try(length(v.database.tde_wallet_password) > 0, false) ? (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.database.tde_wallet_password))) &&
        (length(regexall("[A-Z]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[a-z]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[0-9]", v.database.tde_wallet_password)) >= 2) &&
        (length(regexall("[#_-]", v.database.tde_wallet_password)) >= 2)
      ) : true
    ])
    error_message = "The tde wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }
}

variable "pluggable_databases_configuration" {
  description = "Pluggable Database Configuration."
  default     = null
  type = map(object({
    container_database_id = string # Literal OCID, local database key, or exadata_database_dependency key
    pdb_name              = string

    container_database_admin_password           = optional(string) # Sensitive
    container_database_admin_password_secret_id = optional(string)
    defined_tags                                = optional(map(string))
    freeform_tags                               = optional(map(string))
    kms_key_version_id                          = optional(string)
    pdb_admin_password                          = optional(string) # Sensitive
    pdb_admin_password_secret_id                = optional(string)
    pdb_creation_type_details = optional(object({
      creation_type                  = string
      source_pluggable_database_id   = string
      dblink_user_password           = optional(string)
      dblink_user_password_secret_id = optional(string)
      dblink_username                = optional(string)
      is_thin_clone                  = optional(bool)
      refreshable_clone_details = optional(object({
        is_refreshable_clone = optional(bool)
      }))
      source_container_database_admin_password           = optional(string) # Sensitive
      source_container_database_admin_password_secret_id = optional(string)
    }))
    should_create_pdb_backup           = optional(bool)
    should_pdb_admin_account_be_locked = optional(bool)
    tde_wallet_password                = optional(string)
    tde_wallet_password_secret_id      = optional(string)
  }))
  validation {
    condition = var.pluggable_databases_configuration == null ? true : alltrue(flatten([
      for k, v in var.pluggable_databases_configuration : [
        !(try(length(v.container_database_admin_password) > 0, false) && try(length(trimspace(v.container_database_admin_password_secret_id)) > 0, false)),
        !(try(length(v.pdb_admin_password) > 0, false) && try(length(trimspace(v.pdb_admin_password_secret_id)) > 0, false)),
        !(try(length(v.pdb_creation_type_details.dblink_user_password) > 0, false) && try(length(trimspace(v.pdb_creation_type_details.dblink_user_password_secret_id)) > 0, false)),
        !(try(length(v.pdb_creation_type_details.source_container_database_admin_password) > 0, false) && try(length(trimspace(v.pdb_creation_type_details.source_container_database_admin_password_secret_id)) > 0, false)),
        !(try(length(v.tde_wallet_password) > 0, false) && try(length(trimspace(v.tde_wallet_password_secret_id)) > 0, false))
      ]
    ]))
    error_message = "Each optional pluggable database password must define at most one of its literal value or corresponding secret_id."
  }

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
      try(length(v.pdb_admin_password) > 0, false) ? (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.pdb_admin_password))) &&
        (length(regexall("[A-Z]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[a-z]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[0-9]", v.pdb_admin_password)) >= 2) &&
        (length(regexall("[#_-]", v.pdb_admin_password)) >= 2)
      ) : true
    ])
    error_message = "The pdb admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }

  validation {
    condition = var.pluggable_databases_configuration == null ? true : alltrue([
      for k, v in var.pluggable_databases_configuration :
      try(length(v.tde_wallet_password) > 0, false) ? (
        (can(regex("^[A-Za-z0-9#_-]{9,30}$", v.tde_wallet_password))) &&
        (length(regexall("[A-Z]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[a-z]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[0-9]", v.tde_wallet_password)) >= 2) &&
        (length(regexall("[#_-]", v.tde_wallet_password)) >= 2)
      ) : true
    ])
    error_message = "The tde wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
  }
}
