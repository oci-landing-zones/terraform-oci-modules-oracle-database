# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  default_compartment_id = coalesce(try(var.autonomous_recovery_service_configuration.default_compartment_id, null), var.default_compartment_id)
  default_defined_tags   = merge(coalesce(var.default_defined_tags, {}), coalesce(try(var.autonomous_recovery_service_configuration.default_defined_tags, null), {}))
  default_freeform_tags  = merge(coalesce(var.default_freeform_tags, {}), coalesce(try(var.autonomous_recovery_service_configuration.default_freeform_tags, null), {}))

  recovery_service_subnets_configuration = try(var.autonomous_recovery_service_configuration.recovery_service_subnets, {})
  protection_policies_configuration      = try(var.autonomous_recovery_service_configuration.protection_policies, {})

  recovery_service_subnets = {
    for key, recovery_service_subnet in local.recovery_service_subnets_configuration : key => {
      compartment_id = can(regex("^ocid1\\.", coalesce(try(recovery_service_subnet.compartment_id, null), local.default_compartment_id))) ? coalesce(try(recovery_service_subnet.compartment_id, null), local.default_compartment_id) : var.compartments_dependency[coalesce(try(recovery_service_subnet.compartment_id, null), local.default_compartment_id)].id
      display_name   = recovery_service_subnet.display_name
      vcn_id         = can(regex("^ocid1\\.", recovery_service_subnet.vcn_id)) ? recovery_service_subnet.vcn_id : var.network_dependency.vcns[recovery_service_subnet.vcn_id].id
      subnets = [
        for subnet_id in recovery_service_subnet.subnet_ids :
        can(regex("^ocid1\\.", subnet_id)) ? subnet_id : var.network_dependency.subnets[subnet_id].id
      ]
      nsg_ids = [
        for nsg_id in try(recovery_service_subnet.nsg_ids, []) :
        can(regex("^ocid1\\.", nsg_id)) ? nsg_id : var.network_dependency.network_security_groups[nsg_id].id
      ]
      defined_tags  = merge(local.default_defined_tags, coalesce(try(recovery_service_subnet.defined_tags, null), {}))
      freeform_tags = merge(local.default_freeform_tags, coalesce(try(recovery_service_subnet.freeform_tags, null), {}), local.cislz_module_tag)
    }
  }

  protection_policies = {
    for key, protection_policy in local.protection_policies_configuration : key => {
      compartment_id                  = can(regex("^ocid1\\.", coalesce(try(protection_policy.compartment_id, null), local.default_compartment_id))) ? coalesce(try(protection_policy.compartment_id, null), local.default_compartment_id) : var.compartments_dependency[coalesce(try(protection_policy.compartment_id, null), local.default_compartment_id)].id
      display_name                    = protection_policy.display_name
      backup_retention_period_in_days = protection_policy.backup_retention_period_in_days
      must_enforce_cloud_locality     = try(protection_policy.must_enforce_cloud_locality, null)
      policy_locked_date_time         = try(protection_policy.policy_locked_date_time, null)
      defined_tags                    = merge(local.default_defined_tags, coalesce(try(protection_policy.defined_tags, null), {}))
      freeform_tags                   = merge(local.default_freeform_tags, coalesce(try(protection_policy.freeform_tags, null), {}), local.cislz_module_tag)
    }
  }
}

resource "oci_recovery_recovery_service_subnet" "these" {
  for_each = local.recovery_service_subnets

  compartment_id = each.value.compartment_id
  display_name   = each.value.display_name
  vcn_id         = each.value.vcn_id

  defined_tags  = each.value.defined_tags
  freeform_tags = each.value.freeform_tags
  nsg_ids       = each.value.nsg_ids
  subnets       = each.value.subnets
}

resource "oci_recovery_protection_policy" "these" {
  for_each = local.protection_policies

  backup_retention_period_in_days = each.value.backup_retention_period_in_days
  compartment_id                  = each.value.compartment_id
  display_name                    = each.value.display_name

  defined_tags                = each.value.defined_tags
  freeform_tags               = each.value.freeform_tags
  must_enforce_cloud_locality = each.value.must_enforce_cloud_locality
  policy_locked_date_time     = each.value.policy_locked_date_time
}
