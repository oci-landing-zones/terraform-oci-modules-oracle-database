# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "The module name."
  type        = string
  default     = "autonomous-recovery-service"
}

variable "enable_output" {
  description = "Whether Terraform should enable module output."
  type        = bool
  default     = true
}

variable "compartments_dependency" {
  description = "A map of objects containing externally managed compartments this module may depend on. Each object must contain at least an id attribute."
  type        = map(any)
  default     = null
}

variable "network_dependency" {
  description = "An object containing externally managed VCNs, subnets, and network security groups this module may depend on."
  type = object({
    vcns                    = optional(map(any), {})
    subnets                 = optional(map(any), {})
    network_security_groups = optional(map(any), {})
  })
  default = null
}

variable "default_compartment_id" {
  description = "Default compartment OCID or dependency key for all resources."
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

variable "autonomous_recovery_service_configuration" {
  description = "Autonomous Recovery Service configuration."
  type = object({
    default_compartment_id = optional(string)
    default_defined_tags   = optional(map(string), {})
    default_freeform_tags  = optional(map(string), {})
    recovery_service_subnets = optional(map(object({
      compartment_id = optional(string)
      display_name   = string
      vcn_id         = string
      subnet_ids     = list(string)
      nsg_ids        = optional(list(string), [])
      defined_tags   = optional(map(string), {})
      freeform_tags  = optional(map(string), {})
    })), {})
    protection_policies = optional(map(object({
      compartment_id                  = optional(string)
      display_name                    = string
      backup_retention_period_in_days = number
      must_enforce_cloud_locality     = optional(bool)
      policy_locked_date_time         = optional(string)
      defined_tags                    = optional(map(string), {})
      freeform_tags                   = optional(map(string), {})
    })), {})
  })
  default = {
    recovery_service_subnets = {}
    protection_policies      = {}
  }

  validation {
    condition = alltrue([
      for recovery_service_subnet in values(try(var.autonomous_recovery_service_configuration.recovery_service_subnets, {})) :
      length(recovery_service_subnet.subnet_ids) > 0
    ])
    error_message = "Each recovery service subnet must include at least one subnet_id."
  }

  validation {
    condition = alltrue([
      for recovery_service_subnet in values(try(var.autonomous_recovery_service_configuration.recovery_service_subnets, {})) :
      length(try(recovery_service_subnet.nsg_ids, [])) <= 5
    ])
    error_message = "Each recovery service subnet can include at most five nsg_ids."
  }

  validation {
    condition = alltrue([
      for recovery_policy in values(try(var.autonomous_recovery_service_configuration.protection_policies, {})) :
      recovery_policy.backup_retention_period_in_days >= 14 && recovery_policy.backup_retention_period_in_days <= 95
    ])
    error_message = "Protection policy backup_retention_period_in_days must be between 14 and 95."
  }
}
