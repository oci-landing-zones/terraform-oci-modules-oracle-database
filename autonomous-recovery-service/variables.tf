# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {
  type = string
  default = null
}

variable "autonomous_recovery_service_configuration" {
  description = "Autonomous Recovery Service configuration."

  type = object({
    default_compartment_id = optional(string)
    default_defined_tags   = optional(map(string), {})
    default_freeform_tags  = optional(map(string), {})
    
    recovery_subnets = optional(map(object({
      compartment_id     = optional(string)
      display_name       = string        
      vcn_id             = string                     # the OCID of the VCN or a key reference in var.network_dependency.vcns associated with the recovery service subnet.
      subnet_ids         = list(string)               # list of subnet OCIDs or key references in var.network_dependency.subnets associated with the recovery service subnet.
      nsg_ids            = optional(list(string), []) # list of network security group OCIDs or key references in var.network_dependency.network_security_groups associated with the recovery service subnet.
      enable_default_nsg = optional(bool, true)       # Indicates whether to enable the default network security group for the recovery service subnet. If set to true, the default network security group is enabled for the recovery service subnet.
      enable_iam_policies= optional(bool, true)
      defined_tags       = optional(map(string), {})
      freeform_tags      = optional(map(string), {})
    })), {})

    protection_policies = optional(map(object({
      compartment_id = optional(string)
      display_name   = string
      backup_retention_period_in_days = number       # The maximum number of days to retain backups for a protected database.
      must_enforce_cloud_locality = optional(bool, false) # Indicates whether the protection policy enforces Recovery Service to retain backups in the same cloud service environment where your Oracle Database is provisioned. 
      policy_locked_date_time = optional(string)     # An RFC3339 formatted datetime string that specifies the exact date and time for the retention lock to take effect and permanently lock the retention period defined in the policy.
      defined_tags   = optional(map(string), {})
      freeform_tags  = optional(map(string), {})
    })), {})

    protected_databases = optional(map(object({
      compartment_id = optional(string)
      display_name   = string
      password       = string
      database_unique_name = string
      protection_policy_id = string
      recovery_subnet_ids = list(string) # List of recovery service subnet OCIDs associated with the protected database.
      database_id    = string
      database_size  = number                # The size of the protected database. "XS" - Less than 5GB, "S" - 5GB to 50GB, "M" - 50GB to 500GB, "L" - 500GB to 1TB, "XL" - 1TB to 5TB, "XXL" - Greater than 5TB.
      deletion_schedule = optional(string)   # Defines a preferred schedule to delete a protected database after the source database is terminated. OCI default schedule is "DELETE_AFTER_72_HOURS", meaning the delete operation can occur 72 hours (3 days) after the source database is terminated.
      # The alternate schedule is "DELETE_AFTER_RETENTION_PERIOD". Specify this option if you want to delete a protected database only after the policy-defined backup retention period expires.
      ship_redo_logs = optional(bool, false) # Indicates whether the protected database is configured to ship redo logs to the recovery service. If set to true, redo logs are shipped to the recovery service for the protected database.
      subscription_id  = optional(string)    # The OCID of the cloud service subscription to which you want to link the protected database. For example, specify the Microsoft Azure subscription ID if you want to provision the protected database in Azure. 
      defined_tags   = optional(map(string), {})
      freeform_tags  = optional(map(string), {})
    })), {})
  })

}

variable "enable_output" {
  description = "Whether Terraform should enable the module output."
  type        = bool
  default     = true
}

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "autonomous_recovery_service"
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
    vcns = optional(map(object({
      id = string # the VCN OCID
    })))
    subnets = optional(map(object({
      id = string # the subnet OCID
    })))
    network_security_groups = optional(map(object({
      id = string # the NSG OCID
    })))
  })
  default = null
}

variable "databases_dependency" {
  description = "A map of objects containing the externally managed database resources this module may depend on. Supported resources are 'databases', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with container database OCID."
  type = object({
    databases = optional(map(object({
      id = string
    })))
  })
  default = null
}