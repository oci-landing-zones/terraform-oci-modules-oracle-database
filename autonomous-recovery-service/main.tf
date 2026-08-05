# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_recovery_recovery_service_subnet" "these" {
  for_each       = var.autonomous_recovery_service_configuration.recovery_subnets
  compartment_id = startswith(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id
  display_name   = each.value.display_name
  vcn_id         = startswith(each.value.vcn_id, "ocid1") ? each.value.vcn_id : var.network_dependency.vcns[each.value.vcn_id].id
  subnets        = [for s in each.value.subnet_ids : startswith(s, "ocid1") ? s : var.network_dependency.subnets[s].id]
  nsg_ids        = each.value.enable_default_nsg == true ? [module.autonomous_recovery_service_nsg.flat_map_of_provisioned_networking_resources[each.key].id] : [for n in each.value.nsg_ids : startswith(n, "ocid1") ? n : var.network_dependency.network_security_groups[n].id]
  defined_tags   = coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags)
  freeform_tags  = merge(local.cislz_module_tag, coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags))
}

resource "oci_recovery_protection_policy" "these" {
  for_each                        = var.autonomous_recovery_service_configuration.protection_policies
  compartment_id                  = startswith(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id
  display_name                    = each.value.display_name
  backup_retention_period_in_days = each.value.backup_retention_period_in_days
  must_enforce_cloud_locality     = each.value.must_enforce_cloud_locality
  policy_locked_date_time         = each.value.policy_locked_date_time
  defined_tags                    = coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags)
  freeform_tags                   = merge(local.cislz_module_tag, coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags))
}

resource "oci_recovery_protected_database" "these" {
  for_each             = var.autonomous_recovery_service_configuration.protected_databases
  compartment_id       = startswith(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id
  display_name         = each.value.display_name
  password             = each.value.password
  db_unique_name       = each.value.database_unique_name
  protection_policy_id = startswith(each.value.protection_policy_id, "ocid1") ? each.value.protection_policy_id : oci_recovery_protection_policy.these[each.value.protection_policy_id].id
  database_id          = startswith(each.value.database_id, "ocid1") ? each.value.database_id : var.databases_dependency.databases[each.value.database_id].id
  database_size        = each.value.database_size
  deletion_schedule    = each.value.deletion_schedule
  is_redo_logs_shipped = each.value.ship_redo_logs
  subscription_id      = each.value.subscription_id
  defined_tags         = coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags)
  freeform_tags        = merge(local.cislz_module_tag, coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags))

  dynamic "recovery_service_subnets" {
    for_each = each.value.recovery_subnet_ids
    content {
      recovery_service_subnet_id = startswith(recovery_service_subnets.value, "ocid1") ? recovery_service_subnets.value : oci_recovery_recovery_service_subnet.these[recovery_service_subnets.value].id
    }
  }
}