# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {
  description = "The OCID of the tenancy where the Autonomous Database is created."
  type        = string
}

variable "autonomous_databases_configuration" {
  description = "Configuration object for multiple Autonomous Databases with default values and overrides."

  type = object({
    default_compartment_id = optional(string)
    default_defined_tags   = optional(map(string), {})
    default_freeform_tags  = optional(map(string), {})

    databases = map(object({
      compartment_id              = optional(string)
      display_name                = optional(string)
      db_name                     = string
      db_workload                 = optional(string, "OLTP") # OLTP, DW, AJD, APEX, for Dedicated, only OLTP and DW are allowed
      db_version                  = optional(string, "26ai") # only supported for ADB-Serverless. For ADB-D, the db_version is determined by the container database.
      db_edition                  = optional(string)         # ENTERPRISE_EDITION, STANDARD_EDITION
      is_dedicated                = optional(bool, true)     # Deploying on Dedicated Exadata Infrastructure? If selected, db_workload can only be DW OLTP
      autonomous_container_db_id  = optional(string)         # Only for ADB-D
      is_free_tier                = optional(bool, false)
      is_dev_tier                 = optional(bool, false)
      license_model               = optional(string, "LICENSE_INCLUDED") # default LICENSE_INCLUDED, BRING_YOUR_OWN_LICENSE, must be null for Dedicated
      enable_cpu_auto_scaling     = optional(bool, true)
      enable_storage_auto_scaling = optional(bool, false) # Only for serverless, not applicable for dedicated.
      ecpu_count                  = optional(number, 2)   # 2 is the minimum count for ECPUs. For the same performance of 1 OCPU, the recommended ECPU count is 4. 
      dw_storage_size_in_tbs      = optional(number, 1)   # It is required for "DW" db_workload. Unit is terabytes.
      non_dw_storage_size_in_gbs  = optional(number, 32)  # Use this for all db_workloads, except "DW". Unit is gigabytes (minimum is 20GB). For "DW" use dw_storage_size_in_tbs.
      admin_password              = string
      character_set               = optional(string) # Default is "AL32UTF8"
      national_character_set      = optional(string) # Default is "AL16UTF16"
      backup_retention_in_days    = optional(number) # Retention period, in days, for long-term backups. For ADB-D, this is determined by the value set at Autonomous Container Database
      networking = optional(object({
        whitelisted_ips                       = optional(list(string), []) # does not apply when private endpoint is enabled.
        enable_private_endpoint               = optional(bool, false)
        allow_public_access_without_whitelist = optional(bool, false)
        private_endpoint_ip                   = optional(string)
        subnet_id                             = optional(string)
        network_security_groups               = optional(list(string), []) # Only applicable for Serverless, not applicable for Dedicated.
      }))
      security = optional(object({
        # for ADB-D, tde configuration is inheritated from the autonomous container database
        tde = optional(object({
          deploy_iam_policy_and_dyn_group_for_encryption_key = optional(bool, true)
          existing_oci_vault_id                              = string
          deploy_new_oci_encryption_key                      = optional(bool, true)
          existing_oci_encryption_key_id                     = optional(string) # Required when deploy_new_oci_encryption_key is false and deploy_iam_policy_and_dyn_group_for_encryption_key is true.
        }))
        zpr_attributes = optional(list(object({ # it only applies if networking.enable_private_endpoint is true.
          namespace  = optional(string, "oracle-zpr")
          attr_name  = string
          attr_value = string
          mode       = optional(string, "enforce")
        })))
      }))
      defined_tags  = optional(map(string))
      freeform_tags = optional(map(string))
    }))

  })

  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      length(v.admin_password) >= 12 &&             # between 12 and 30 characters long
      length(v.admin_password) <= 30 &&             # between 12 and 30 characters long
      can(regex("[A-Z]", v.admin_password)) &&      # contain at least 1 uppercase
      can(regex("[a-z]", v.admin_password)) &&      # contain at least 1 lowercase
      can(regex("[0-9]", v.admin_password)) &&      # contains at least 1 numeric character
      !can(regex("\"", v.admin_password)) &&        # cannot contain the double quote symbol (")
      !can(regex("admin", lower(v.admin_password))) # cannot contain the username "admin", regardless of casing.
    ])
    error_message = "Password must be between 12 and 30 characters, contain at least one uppercase letter, one lowercase letter, one numeric character, and cannot contain double quotes or 'admin' (case insensitive)."
  }
  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      v.is_dedicated == false || (v.is_dedicated == true && v.autonomous_container_db_id != null)
    ])
    error_message = "Container Database ID must be provided to deploy on Dedicated Exadata Infrastructure. To provision a serverless Autonomous database, set is_dedicated=false."
  }
  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      try(v.is_dedicated, true) == true ||
      try(v.security.tde.deploy_iam_policy_and_dyn_group_for_encryption_key, false) == false ||
      try(v.security.tde.deploy_new_oci_encryption_key, false) == true ||
      try(v.security.tde.existing_oci_encryption_key_id, null) != null
    ])
    error_message = "existing_oci_encryption_key_id is required when ADB Shared/Serverless TDE deploys IAM policy and dynamic group with deploy_new_oci_encryption_key=false."
  }
  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      try(v.networking.enable_private_endpoint, false) == false || try(v.networking.subnet_id, null) != null
    ])
    error_message = "subnet_id is required when networking.enable_private_endpoint is true."
  }
  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      try(v.is_dedicated, true) == true ||
      try(v.networking.enable_private_endpoint, false) == true ||
      length(try(v.networking.whitelisted_ips, [])) > 0 ||
      try(v.networking.allow_public_access_without_whitelist, false) == true
    ])
    error_message = "ADB Shared/Serverless must set networking.enable_private_endpoint=true, provide networking.whitelisted_ips, or explicitly set networking.allow_public_access_without_whitelist=true."
  }
  validation {
    condition = var.autonomous_databases_configuration.databases == null ? true : alltrue([
      for k, v in var.autonomous_databases_configuration.databases :
      v.compartment_id != null || var.autonomous_databases_configuration.default_compartment_id != null
    ])
    error_message = "Each Autonomous Database must set compartment_id or autonomous_databases_configuration.default_compartment_id."
  }
}

variable "enable_output" {
  description = "Whether Terraform should enable the module output."
  type        = bool
  default     = true
}

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "autonomous_database"
}

variable "compartments_dependency" {
  description = "A map of objects containing the externally managed compartments this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the compartment OCID) of string type."
  type = map(object({
    id = string # the compartment OCID
  }))
  default = null
}

variable "network_dependency" {
  description = "An object containing the externally managed network resources this module may depend on. Supported resources are 'subnets', and 'network_security_groups', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with the subnet or NSG OCID."
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

variable "vaults_dependency" {
  description = "A map of objects containing the externally managed vaults this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the vault OCID) of string type."
  type = map(object({
    id = string # the vault OCID.
  }))
  default = null
}

variable "databases_dependency" {
  description = "A map of objects containing the externally managed database resources this module may depend on. Supported resources are 'container_databases', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with container database OCID."
  type = object({
    container_databases = optional(map(object({
      id = string
    })))
  })
  default = null
}
