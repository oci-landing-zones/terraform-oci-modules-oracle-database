# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
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
    admin_password                   = v.admin_password
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

resource "oci_database_autonomous_database" "these" {
  depends_on                          = [null_resource.wait]
  for_each                            = local.db_configs
  compartment_id                      = each.value.compartment_id
  subnet_id                           = each.value.subnet_id
  db_name                             = each.value.db_name
  db_version                          = each.value.db_version
  database_edition                    = each.value.db_edition
  is_dedicated                        = each.value.is_dedicated
  autonomous_container_database_id    = each.value.autonomous_container_database_id
  compute_model                       = "ECPU"
  compute_count                       = each.value.ecpu_count
  data_storage_size_in_tbs            = each.value.data_storage_size_in_tbs
  data_storage_size_in_gb             = each.value.data_storage_size_in_gbs
  admin_password                      = each.value.admin_password
  display_name                        = each.value.display_name
  db_workload                         = each.value.db_workload
  is_free_tier                        = each.value.is_free_tier
  is_dev_tier                         = each.value.is_dev_tier
  license_model                       = each.value.license_model
  is_auto_scaling_enabled             = each.value.enable_cpu_auto_scaling
  is_auto_scaling_for_storage_enabled = each.value.enable_storage_auto_scaling
  character_set                       = each.value.character_set
  ncharacter_set                      = each.value.national_character_set
  backup_retention_period_in_days     = each.value.backup_retention_in_days
  nsg_ids                             = each.value.nsg_ids
  whitelisted_ips                     = each.value.whitelisted_ips
  defined_tags                        = each.value.defined_tags
  freeform_tags                       = each.value.freeform_tags
  private_endpoint_label              = each.value.private_endpoint_label
  private_endpoint_ip                 = each.value.private_endpoint_ip
  security_attributes                 = each.value.security_attributes
  dynamic "encryption_key" {
    for_each = each.value.is_dedicated == false && (each.value.deploy_new_oci_encryption_key == true || each.value.oci_encryption_key_id != null) ? [1] : []
    content {
      autonomous_database_provider = "OCI"
      kms_key_id                   = try(module.master_keys[0].keys["${each.key}-KEY"].id, each.value.oci_encryption_key_id)
      vault_id                     = each.value.oci_vault_id
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.compartment_id != null && can(regex("^ocid1\\.compartment\\.", each.value.compartment_id))
      error_message = "compartment_id must be a compartment OCID or a key in compartments_dependency."
    }
    precondition {
      condition     = each.value.is_dedicated == false || (each.value.autonomous_container_database_id != null && can(regex("^ocid1\\.autonomouscontainerdatabase\\.", each.value.autonomous_container_database_id)))
      error_message = "autonomous_container_db_id must be an Autonomous Container Database OCID or a key in databases_dependency.container_databases."
    }
    precondition {
      condition     = each.value.enable_private_endpoint == false || (each.value.subnet_id != null && can(regex("^ocid1\\.subnet\\.", each.value.subnet_id)))
      error_message = "networking.subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }
    precondition {
      condition     = each.value.enable_private_endpoint == false || alltrue([for id in coalesce(each.value.nsg_ids, []) : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "networking.network_security_groups must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }
    precondition {
      condition     = each.value.is_dedicated == true || each.value.oci_vault_id_input == null || (each.value.oci_vault_id != null && can(regex("^ocid1\\.vault\\.", each.value.oci_vault_id)))
      error_message = "ADB Shared/Serverless TDE vault keys must resolve through vaults_dependency. A temporary 1.1.0 compatibility fallback accepts a vault OCID stored in kms_dependency, but this fallback is deprecated."
    }
    precondition {
      condition     = each.value.is_dedicated == true || each.value.deploy_new_oci_encryption_key == true || each.value.oci_encryption_key_id_input == null || (each.value.oci_encryption_key_id != null && can(regex("^ocid1\\.key\\.", each.value.oci_encryption_key_id)))
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
