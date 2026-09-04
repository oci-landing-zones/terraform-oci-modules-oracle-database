# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_kms_vault" "these" {
  for_each = { for k, v in var.autonomous_databases_configuration.databases : k => local.tde_vault_ids[k] if try(v.is_dedicated, true) == false && local.tde_vault_ids[k] != null && (try(v.security.tde.deploy_iam_policy_and_dyn_group_for_encryption_key, false) == true || try(v.security.tde.deploy_new_oci_encryption_key, false) == true) }
  vault_id = each.value
}

data "oci_kms_key" "these" {
  for_each            = { for k, v in var.autonomous_databases_configuration.databases : k => try(v.security.tde.existing_oci_encryption_key_id, null) if try(v.is_dedicated, true) == false && try(v.security.tde.existing_oci_encryption_key_id, null) != null && try(v.security.tde.deploy_new_oci_encryption_key, false) == false && try(v.security.tde.deploy_iam_policy_and_dyn_group_for_encryption_key, false) == true && local.tde_vault_ids[k] != null && (try(length(regexall("^ocid1.*$", v.security.tde.existing_oci_encryption_key_id)) > 0, false) || try(contains(keys(var.kms_dependency), v.security.tde.existing_oci_encryption_key_id), false)) }
  key_id              = length(regexall("^ocid1.*$", each.value)) > 0 ? each.value : var.kms_dependency[each.value].id
  management_endpoint = data.oci_kms_vault.these[each.key].management_endpoint
}

locals {

  vaults_configuration = {
    default_compartment_id = null
    keys = { for k, v in local.db_configs : "${k}-KEY" => {
      name           = "${v.db_name}-key"
      vault_id       = data.oci_kms_vault.these[k].vault_id
      compartment_id = v.compartment_id
    } if v.deploy_new_oci_encryption_key && contains(keys(data.oci_kms_vault.these), k) }
  }

  dynamic_groups_configuration = {
    dynamic_groups = { for k, v in local.db_configs : "${k}-DYNAMIC-GROUP" => {
      name        = "${v.db_name}-dynamic-group",
      description = "Dynamic group for ${v.db_name} accessing Key Management service (aka Vault service).",
      # Preserve the 1.1.0 rule so an in-place 1.1.0-to-1.2.0 upgrade does
      # not modify an existing dynamic group. A tighter rule can be made an
      # explicit future change.
      matching_rule = "ALL {resource.compartment.id = '${v.compartment_id}'}"
    } if v.deploy_iam_policy_and_dyn_group_for_encryption_key }
  }

  # required policies for ADB-S: read vaults, use keys
  #                       ADB-D: read vaults, manage keys
  policies_configuration = {
    supplied_policies = { for k, v in local.db_configs : "${k}-POLICY" => {
      name           = "${v.db_name}-policy"
      description    = "Policy for ${v.db_name} to use encryption key from Vault service."
      compartment_id = var.tenancy_ocid # policy created at tenancy level, since the vault and key can be in different compartments
      statements = [
        "allow dynamic-group ${v.db_name}-dynamic-group to read vaults in compartment id ${data.oci_kms_vault.these[k].compartment_id} where target.vault.id = '${data.oci_kms_vault.these[k].id}'",
        # ADB-S requires 'use' keys, ADB-D requires 'manage' keys in the Container database level.
        "allow dynamic-group ${v.db_name}-dynamic-group to use keys in compartment id ${try(v.deploy_new_oci_encryption_key, false) == true ? module.master_keys[0].keys["${k}-KEY"].compartment_id : data.oci_kms_key.these[k].compartment_id} where target.key.id = '${try(v.deploy_new_oci_encryption_key, false) == true ? module.master_keys[0].keys["${k}-KEY"].id : data.oci_kms_key.these[k].id}'"
      ]
    } if v.deploy_iam_policy_and_dyn_group_for_encryption_key && contains(keys(data.oci_kms_vault.these), k) && (try(v.deploy_new_oci_encryption_key, false) == true || contains(keys(data.oci_kms_key.these), k)) }
  }

  adb_tde_iam_wait_inputs = {
    for k, v in local.db_configs : k => {
      db_name                         = v.db_name
      compartment_id                  = v.compartment_id
      vault_id                        = v.oci_vault_id
      encryption_key_id               = try(v.deploy_new_oci_encryption_key, false) == true ? "${k}-KEY" : v.oci_encryption_key_id
      deploy_new_oci_encryption_key   = v.deploy_new_oci_encryption_key
      deploy_iam_policy_and_dyn_group = v.deploy_iam_policy_and_dyn_group_for_encryption_key
    } if v.deploy_iam_policy_and_dyn_group_for_encryption_key && contains(keys(data.oci_kms_vault.these), k) && (try(v.deploy_new_oci_encryption_key, false) == true || contains(keys(data.oci_kms_key.these), k))
  }
}

module "dynamic_groups" {
  count                        = local.dynamic_groups_configuration.dynamic_groups != {} ? 1 : 0
  source                       = "github.com/oci-landing-zones/terraform-oci-modules-iam//dynamic-groups?ref=v0.3.0"
  providers                    = { oci = oci.home }
  tenancy_ocid                 = var.tenancy_ocid
  dynamic_groups_configuration = local.dynamic_groups_configuration
}


module "policies" {
  count                  = local.policies_configuration.supplied_policies != {} ? 1 : 0
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-iam//policies?ref=v0.3.0"
  providers              = { oci = oci.home }
  tenancy_ocid           = var.tenancy_ocid
  policies_configuration = local.policies_configuration
}

module "master_keys" {
  count  = local.vaults_configuration.keys != {} ? 1 : 0
  source = "github.com/oci-landing-zones/terraform-oci-modules-security//vaults?ref=v0.2.3"
  providers = {
    oci      = oci
    oci.home = oci.home
  }
  vaults_configuration = local.vaults_configuration
}
