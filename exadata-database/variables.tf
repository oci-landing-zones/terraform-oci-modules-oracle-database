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
    exascale_db_storage_vaults = optional(map(object({
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
    data_storage_percentage      = optional(number) #. Accepted values are 35, 40, 60 and 80.
    data_storage_size_in_tbs     = optional(number)
    db_node_storage_size_in_gbs  = optional(number)
    db_servers                   = optional(list(string))
    defined_tags                 = optional(map(string))
    exascale_db_storage_vault_id = optional(string) # Literal vault OCID or key in local/external exascale_db_storage_vaults.
    freeform_tags                = optional(map(string))
    domain                       = optional(string)
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

variable "exascale_db_storage_vaults_configuration" {
  description = "Exascale DB Storage Vault configuration forwarded unchanged to ../exascale-db-storage-vault. Set exadata_infrastructure_id for Dedicated Infrastructure mode."
  type        = any
  default     = null
}

# These inputs are intentionally unconstrained at this boundary. ../common-database
# owns their typed contract and validation, and receives each value unchanged.
variable "cloud_db_homes_configuration" {
  description = "DB Home configuration forwarded unchanged to ../common-database."
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
