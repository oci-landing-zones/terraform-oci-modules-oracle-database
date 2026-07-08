# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "recovery_service_subnets" {
  description = "Recovery Service subnet resources indexed by input key."
  value = var.enable_output ? {
    for key, recovery_service_subnet in oci_recovery_recovery_service_subnet.these : key => {
      compartment_id = recovery_service_subnet.compartment_id
      display_name   = recovery_service_subnet.display_name
      id             = recovery_service_subnet.id
      nsg_ids        = recovery_service_subnet.nsg_ids
      state          = recovery_service_subnet.state
      subnets        = recovery_service_subnet.subnets
      vcn_id         = recovery_service_subnet.vcn_id
    }
  } : null
}

output "protection_policies" {
  description = "Protection policy resources indexed by input key."
  value = var.enable_output ? {
    for key, protection_policy in oci_recovery_protection_policy.these : key => {
      backup_retention_period_in_days = protection_policy.backup_retention_period_in_days
      compartment_id                  = protection_policy.compartment_id
      display_name                    = protection_policy.display_name
      id                              = protection_policy.id
      is_predefined_policy            = protection_policy.is_predefined_policy
      must_enforce_cloud_locality     = protection_policy.must_enforce_cloud_locality
      policy_locked_date_time         = protection_policy.policy_locked_date_time
      state                           = protection_policy.state
    }
  } : null
}
