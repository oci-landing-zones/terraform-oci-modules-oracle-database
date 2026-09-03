# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_secrets_secretbundle" "protected_database_password" {
  for_each = {
    for k, v in var.autonomous_recovery_service_configuration.protected_databases : k => startswith(try(trimspace(v.password_secret_id), ""), "ocid1") ? try(trimspace(v.password_secret_id), "") : trimspace(var.secrets_dependency[try(trimspace(v.password_secret_id), "")].id) if try(trimspace(v.password_secret_id), "") != ""
  }
  secret_id = trimspace(each.value)
  stage     = "CURRENT"
}

locals {
  protected_database_compartment_ids = {
    for k, v in var.autonomous_recovery_service_configuration.protected_databases : k => startswith(trimspace(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)), "ocid1") ? trimspace(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)) : trimspace(var.compartments_dependency[trimspace(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id))].id)
  }
  oracle_predefined_protection_policies = { # these OCIDs are the same across tenancies and regions.
    "platinum" = "ocid1.recoveryservicepolicy.region1..aaaaaaaac2vcgrt63a5nyaukbxa6qjciozkcjor2d7o7ytv3rdho7rzgo62q"
    "gold"     = "ocid1.recoveryservicepolicy.region1..aaaaaaaa7hpkscem4speevhrbobgafoz3olxi4g5q6po57ogoiyhvhlol25q"
    "silver"   = "ocid1.recoveryservicepolicy.region1..aaaaaaaaqfdodiimpk7ylahyae7dxxm6xq5qkluoqj2szt6u5liq7e2bia5q"
    "bronze"   = "ocid1.recoveryservicepolicy.region1..aaaaaaaam22xkw32t524xvst7dbxz4qsxtwetmfnnxfsgslbq664vya5jbkq"
  }
}

resource "oci_recovery_recovery_service_subnet" "these" {
  for_each       = var.autonomous_recovery_service_configuration.recovery_subnets
  compartment_id = startswith(trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)), "ocid1") ? trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)) : trimspace(var.compartments_dependency[trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id))].id)
  display_name   = trimspace(each.value.display_name)
  vcn_id         = startswith(trimspace(each.value.vcn_id), "ocid1") ? trimspace(each.value.vcn_id) : trimspace(var.network_dependency.vcns[trimspace(each.value.vcn_id)].id)
  subnets        = [for s in each.value.subnet_ids : startswith(trimspace(s), "ocid1") ? trimspace(s) : trimspace(var.network_dependency.subnets[trimspace(s)].id)]
  nsg_ids        = each.value.enable_default_nsg == true ? [module.autonomous_recovery_service_nsg.flat_map_of_provisioned_networking_resources[each.key].id] : [for n in each.value.nsg_ids : startswith(trimspace(n), "ocid1") ? trimspace(n) : trimspace(var.network_dependency.network_security_groups[trimspace(n)].id)]
  defined_tags   = { for k, v in coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags) : trimspace(k) => trimspace(v) }
  freeform_tags  = merge(local.cislz_module_tag, { for k, v in coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags) : trimspace(k) => trimspace(v) })
}

resource "oci_recovery_protection_policy" "these" {
  for_each                        = var.autonomous_recovery_service_configuration.protection_policies
  compartment_id                  = startswith(trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)), "ocid1") ? trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)) : trimspace(var.compartments_dependency[trimspace(coalesce(each.value.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id))].id)
  display_name                    = trimspace(each.value.display_name)
  backup_retention_period_in_days = each.value.backup_retention_period_in_days
  must_enforce_cloud_locality     = each.value.must_enforce_cloud_locality
  policy_locked_date_time         = each.value.policy_locked_date_time != null ? trimspace(each.value.policy_locked_date_time) : null
  defined_tags                    = { for k, v in coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags) : trimspace(k) => trimspace(v) }
  freeform_tags                   = merge(local.cislz_module_tag, { for k, v in coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags) : trimspace(k) => trimspace(v) })
}

resource "oci_recovery_protected_database" "these" {
  for_each             = var.autonomous_recovery_service_configuration.protected_databases
  compartment_id       = local.protected_database_compartment_ids[each.key]
  display_name         = trimspace(each.value.display_name)
  password             = sensitive(each.value.password != null ? trimspace(each.value.password) : base64decode(data.oci_secrets_secretbundle.protected_database_password[each.key].secret_bundle_content.0.content))
  db_unique_name       = trimspace(each.value.database_unique_name)
  protection_policy_id = startswith(trimspace(each.value.protection_policy_id), "ocid1") ? trimspace(each.value.protection_policy_id) : contains(keys(oci_recovery_protection_policy.these), trimspace(each.value.protection_policy_id)) ? oci_recovery_protection_policy.these[trimspace(each.value.protection_policy_id)].id : local.oracle_predefined_protection_policies[lower(trimspace(each.value.protection_policy_id))]
  database_id          = startswith(trimspace(each.value.database_id), "ocid1") ? trimspace(each.value.database_id) : trimspace(var.databases_dependency.databases[trimspace(each.value.database_id)].id)
  database_size        = trimspace(each.value.database_size)
  deletion_schedule    = each.value.deletion_schedule != null ? trimspace(each.value.deletion_schedule) : null
  is_redo_logs_shipped = each.value.ship_redo_logs
  subscription_id      = each.value.subscription_id != null ? trimspace(each.value.subscription_id) : null
  defined_tags         = { for k, v in coalesce(each.value.defined_tags, var.autonomous_recovery_service_configuration.default_defined_tags) : trimspace(k) => trimspace(v) }
  freeform_tags        = merge(local.cislz_module_tag, { for k, v in coalesce(each.value.freeform_tags, var.autonomous_recovery_service_configuration.default_freeform_tags) : trimspace(k) => trimspace(v) })

  dynamic "recovery_service_subnets" {
    for_each = each.value.recovery_subnet_ids
    content {
      recovery_service_subnet_id = startswith(trimspace(recovery_service_subnets.value), "ocid1") ? trimspace(recovery_service_subnets.value) : oci_recovery_recovery_service_subnet.these[trimspace(recovery_service_subnets.value)].id
    }
  }
}
