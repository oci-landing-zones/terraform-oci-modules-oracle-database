# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  admin_password_secret_id_inputs = {
    for k, v in var.autonomous_databases_configuration.databases :
    k => try(trimspace(v.admin_password_secret_id), "")
  }

  admin_password_secret_ids = {
    for k, secret_ref in local.admin_password_secret_id_inputs :
    k => secret_ref == "" ? null : (
      can(regex("^ocid1\\.vaultsecret\\.", secret_ref))
      ? secret_ref
      : try(trimspace(var.secrets_dependency[secret_ref].id), null)
    )
  }

  admin_passwords = {
    for k, v in var.autonomous_databases_configuration.databases :
    k => sensitive(
      try(length(v.admin_password) > 0, false)
      ? v.admin_password
      : try(base64decode(data.oci_secrets_secretbundle.admin_password[k].secret_bundle_content[0].content), null)
    )
  }

  tde_vault_id_inputs = {
    for k, v in var.autonomous_databases_configuration.databases :
    k => try(v.is_dedicated, true) == true ? null : try(v.security.tde.existing_oci_vault_id, null)
  }

  tde_vault_ids = {
    for k, input in local.tde_vault_id_inputs :
    k => input == null ? null : (
      length(regexall("^ocid1\\.vault\\.", input)) > 0 ? input : try(coalesce(
        try(var.vaults_dependency[input].id, null),
        try(can(regex("^ocid1\\.vault\\.", var.kms_dependency[input].id)) ? var.kms_dependency[input].id : null, null)
      ), null)
    )
  }

  db_configs = { for k, v in var.autonomous_databases_configuration.databases : k => {
    compartment_id                   = v.compartment_id != null ? (length(regexall("^ocid1.*$", v.compartment_id)) > 0 ? v.compartment_id : try(var.compartments_dependency[v.compartment_id].id, null)) : (var.autonomous_databases_configuration.default_compartment_id != null ? (length(regexall("^ocid1.*$", var.autonomous_databases_configuration.default_compartment_id)) > 0 ? var.autonomous_databases_configuration.default_compartment_id : try(var.compartments_dependency[var.autonomous_databases_configuration.default_compartment_id].id, null)) : null)
    db_name                          = v.db_name
    db_version                       = v.is_dedicated ? null : v.db_version
    db_edition                       = v.db_edition
    is_dedicated                     = v.is_dedicated
    autonomous_container_database_id = v.is_dedicated ? (try(length(regexall("^ocid1\\.autonomouscontainerdatabase\\.", v.autonomous_container_db_id)) > 0, false) ? v.autonomous_container_db_id : try(var.databases_dependency.container_databases[v.autonomous_container_db_id].id, null)) : null
    ecpu_count                       = v.ecpu_count
    data_storage_size_in_gbs         = v.db_workload == "DW" ? null : v.non_dw_storage_size_in_gbs
    data_storage_size_in_tbs         = v.db_workload == "DW" ? v.dw_storage_size_in_tbs : null
    admin_password_secret_id_input   = local.admin_password_secret_id_inputs[k]
    admin_password_secret_id         = local.admin_password_secret_ids[k]
    display_name                     = coalesce(v.display_name, v.db_name)
    db_workload                      = v.db_workload
    is_free_tier                     = v.is_free_tier
    is_dev_tier                      = v.is_dev_tier
    license_model                    = v.is_dedicated ? null : v.license_model # default "LICENSE_INCLUDED", defaults to null for dedicated
    enable_cpu_auto_scaling          = v.enable_cpu_auto_scaling
    enable_storage_auto_scaling      = v.is_dedicated ? null : v.enable_storage_auto_scaling
    character_set                    = v.character_set
    national_character_set           = v.national_character_set
    backup_retention_in_days         = v.is_dedicated ? null : v.backup_retention_in_days
    whitelisted_ips                  = try(v.networking.whitelisted_ips, null) != null ? v.networking.whitelisted_ips : null

    enable_private_endpoint = try(v.networking.enable_private_endpoint, false)
    private_endpoint_label  = try(v.networking.enable_private_endpoint, false) == true ? "${lower(v.db_name)}-private-endpoint" : ""
    private_endpoint_ip     = try(v.networking.enable_private_endpoint, false) == true && try(v.networking.private_endpoint_ip, null) != null ? v.networking.private_endpoint_ip : null
    nsg_ids                 = v.is_dedicated ? null : try(v.networking.enable_private_endpoint, false) == true ? [for nsg in coalesce(try(v.networking.network_security_groups, null), []) : (length(regexall("^ocid1.*$", nsg)) > 0 ? nsg : try(var.network_dependency.network_security_groups[nsg].id, null))] : null
    subnet_id               = try(v.networking.enable_private_endpoint, false) == true && try(v.networking.subnet_id, null) != null ? ((length(regexall("^ocid1.*$", v.networking.subnet_id)) > 0 ? v.networking.subnet_id : try(var.network_dependency.subnets[v.networking.subnet_id].id, null))) : null
    security_attributes     = try(v.networking.enable_private_endpoint, false) == true ? (try(v.security.zpr_attributes, null) != null ? merge([for a in v.security.zpr_attributes : { "${a.namespace}.${a.attr_name}.value" : a.attr_value, "${a.namespace}.${a.attr_name}.mode" : a.mode }]...) : null) : null

    # tde attributes are inherited from ACDB when deploying on a dedicated exa infra
    deploy_iam_policy_and_dyn_group_for_encryption_key = v.is_dedicated == true ? false : try(v.security.tde.deploy_iam_policy_and_dyn_group_for_encryption_key, false)
    deploy_new_oci_encryption_key                      = v.is_dedicated == true ? false : try(v.security.tde.deploy_new_oci_encryption_key, false)
    oci_vault_id_input                                 = local.tde_vault_id_inputs[k]
    oci_encryption_key_id_input                        = v.is_dedicated == true ? null : try(v.security.tde.existing_oci_encryption_key_id, null)
    oci_vault_id                                       = local.tde_vault_ids[k]
    oci_encryption_key_id                              = v.is_dedicated == true ? null : try(v.security.tde.existing_oci_encryption_key_id, null) != null ? (length(regexall("^ocid1.*$", v.security.tde.existing_oci_encryption_key_id)) > 0 ? v.security.tde.existing_oci_encryption_key_id : try(var.kms_dependency[v.security.tde.existing_oci_encryption_key_id].id, null)) : null

    defined_tags  = coalesce(v.defined_tags, var.autonomous_databases_configuration.default_defined_tags)
    freeform_tags = coalesce(v.freeform_tags, var.autonomous_databases_configuration.default_freeform_tags)
    }
  }
}

data "oci_secrets_secretbundle" "admin_password" {
  for_each = {
    for k, secret_ref in local.admin_password_secret_id_inputs :
    k => local.admin_password_secret_ids[k]
    if secret_ref != ""
  }

  secret_id = each.value
  stage     = "CURRENT"

  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "admin_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current admin password secret content must be nonempty valid Base64."
    }
  }
}

resource "oci_database_autonomous_database" "these" {
  depends_on                       = [null_resource.wait]
  for_each                         = var.autonomous_databases_configuration.databases
  compartment_id                   = local.db_configs[each.key].compartment_id
  subnet_id                        = local.db_configs[each.key].subnet_id
  db_name                          = local.db_configs[each.key].db_name
  db_version                       = local.db_configs[each.key].db_version
  database_edition                 = local.db_configs[each.key].db_edition
  is_dedicated                     = local.db_configs[each.key].is_dedicated
  autonomous_container_database_id = local.db_configs[each.key].autonomous_container_database_id
  compute_model                    = "ECPU"
  compute_count                    = local.db_configs[each.key].ecpu_count
  data_storage_size_in_tbs         = local.db_configs[each.key].data_storage_size_in_tbs
  data_storage_size_in_gb          = local.db_configs[each.key].data_storage_size_in_gbs
  admin_password = sensitive(
    try(length(each.value.admin_password) > 0, false)
    ? each.value.admin_password
    : try(base64decode(data.oci_secrets_secretbundle.admin_password[each.key].secret_bundle_content[0].content), null)
  )
  display_name                        = local.db_configs[each.key].display_name
  db_workload                         = local.db_configs[each.key].db_workload
  is_free_tier                        = local.db_configs[each.key].is_free_tier
  is_dev_tier                         = local.db_configs[each.key].is_dev_tier
  license_model                       = local.db_configs[each.key].license_model
  is_auto_scaling_enabled             = local.db_configs[each.key].enable_cpu_auto_scaling
  is_auto_scaling_for_storage_enabled = local.db_configs[each.key].enable_storage_auto_scaling
  character_set                       = local.db_configs[each.key].character_set
  ncharacter_set                      = local.db_configs[each.key].national_character_set
  backup_retention_period_in_days     = local.db_configs[each.key].backup_retention_in_days
  nsg_ids                             = local.db_configs[each.key].nsg_ids
  whitelisted_ips                     = local.db_configs[each.key].whitelisted_ips
  defined_tags                        = local.db_configs[each.key].defined_tags
  freeform_tags                       = local.db_configs[each.key].freeform_tags
  private_endpoint_label              = local.db_configs[each.key].private_endpoint_label
  private_endpoint_ip                 = local.db_configs[each.key].private_endpoint_ip
  security_attributes                 = local.db_configs[each.key].security_attributes
  dynamic "encryption_key" {
    for_each = local.db_configs[each.key].is_dedicated == false && (local.db_configs[each.key].deploy_new_oci_encryption_key == true || local.db_configs[each.key].oci_encryption_key_id != null) ? [1] : []
    content {
      autonomous_database_provider = "OCI"
      kms_key_id                   = try(module.master_keys[0].keys["${each.key}-KEY"].id, local.db_configs[each.key].oci_encryption_key_id)
      vault_id                     = local.db_configs[each.key].oci_vault_id
    }
  }

  lifecycle {
    # OCI returns these service-managed provenance tags through defined_tags.
    # Do not make callers remove them while retaining management of all other
    # defined tags.
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
      # OCI accepts an explicit endpoint IP during creation but does not
      # reliably apply a later change to an existing Autonomous Database.
      # Preserve the OCI-assigned IP for 1.1.0 upgrades and avoid a
      # perpetual update plan.
      private_endpoint_ip,
    ]

    precondition {
      condition     = local.db_configs[each.key].compartment_id != null && can(regex("^ocid1\\.compartment\\.", local.db_configs[each.key].compartment_id))
      error_message = "compartment_id must be a compartment OCID or a key in compartments_dependency."
    }
    precondition {
      condition = try(
        length(nonsensitive(local.admin_passwords[each.key])) >= 12 &&
        length(nonsensitive(local.admin_passwords[each.key])) <= 30 &&
        can(regex("[A-Z]", nonsensitive(local.admin_passwords[each.key]))) &&
        can(regex("[a-z]", nonsensitive(local.admin_passwords[each.key]))) &&
        can(regex("[0-9]", nonsensitive(local.admin_passwords[each.key]))) &&
        !can(regex("\"", nonsensitive(local.admin_passwords[each.key]))) &&
        !can(regex("admin", lower(nonsensitive(local.admin_passwords[each.key])))),
        false
      )
      error_message = "Password must be between 12 and 30 characters, contain at least one uppercase letter, one lowercase letter, one numeric character, and cannot contain double quotes or 'admin' (case insensitive)."
    }
    precondition {
      condition     = local.db_configs[each.key].is_dedicated == false || (local.db_configs[each.key].autonomous_container_database_id != null && can(regex("^ocid1\\.autonomouscontainerdatabase\\.", local.db_configs[each.key].autonomous_container_database_id)))
      error_message = "autonomous_container_db_id must be an Autonomous Container Database OCID or a key in databases_dependency.container_databases."
    }
    precondition {
      condition     = local.db_configs[each.key].enable_private_endpoint == false || (local.db_configs[each.key].subnet_id != null && can(regex("^ocid1\\.subnet\\.", local.db_configs[each.key].subnet_id)))
      error_message = "networking.subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }
    precondition {
      condition     = local.db_configs[each.key].enable_private_endpoint == false || alltrue([for id in coalesce(local.db_configs[each.key].nsg_ids, []) : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "networking.network_security_groups must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }
    precondition {
      condition     = local.db_configs[each.key].is_dedicated == true || local.db_configs[each.key].oci_vault_id_input == null || (local.db_configs[each.key].oci_vault_id != null && can(regex("^ocid1\\.vault\\.", local.db_configs[each.key].oci_vault_id)))
      error_message = "ADB Shared/Serverless TDE vault keys must resolve through vaults_dependency. A temporary 1.1.0 compatibility fallback accepts a vault OCID stored in kms_dependency, but this fallback is deprecated."
    }
    precondition {
      condition     = local.db_configs[each.key].is_dedicated == true || local.db_configs[each.key].deploy_new_oci_encryption_key == true || local.db_configs[each.key].oci_encryption_key_id_input == null || (local.db_configs[each.key].oci_encryption_key_id != null && can(regex("^ocid1\\.key\\.", local.db_configs[each.key].oci_encryption_key_id)))
      error_message = "ADB Shared/Serverless TDE encryption key IDs must resolve through kms_dependency. Use a literal key OCID or a valid kms_dependency key."
    }
  }
}
resource "null_resource" "wait" {
  depends_on = [module.policies]
  triggers = {
    tde_iam_fingerprint = sha1(jsonencode(local.adb_tde_iam_wait_inputs))
  }
  provisioner "local-exec" {
    command = "sleep 30"
  }
}
