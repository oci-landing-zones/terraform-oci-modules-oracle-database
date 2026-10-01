# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Normalize the nested DB System input once before resource creation.
locals {
  additional_pdbs = {
    for pdb in flatten([
      for db_system_key, db_system in try(coalesce(var.db_systems_configuration.db_systems, {}), {}) : [
        for pdb_key, definition in try(db_system.db_home.database.additional_pdbs, {}) : {
          key                          = "${db_system_key}.${pdb_key}"
          db_system_key                = db_system_key
          pdb_name                     = definition.pdb_name
          pdb_admin_password           = try(definition.pdb_admin_password, null)
          pdb_admin_password_secret_id = try(definition.pdb_admin_password_secret_id, null)
          defined_tags                 = try(definition.defined_tags, null)
          freeform_tags                = try(definition.freeform_tags, null)
        }
      ]
    ]) : pdb.key => pdb
  }

  db_systems = try(coalesce(var.db_systems_configuration.db_systems, {}), {})

  additional_pdb_secret_ids = {
    for key, pdb in local.additional_pdbs : key => length(regexall("^ocid1\\.", pdb.pdb_admin_password_secret_id)) > 0 ? pdb.pdb_admin_password_secret_id : try(var.secrets_dependency[pdb.pdb_admin_password_secret_id].id, null)
    if pdb.pdb_admin_password == null && pdb.pdb_admin_password_secret_id != null && (
      length(regexall("^ocid1\\.", pdb.pdb_admin_password_secret_id)) > 0 || try(var.secrets_dependency[pdb.pdb_admin_password_secret_id].id, null) != null
    )
  }

  additional_pdb_admin_passwords = {
    for key, pdb in local.additional_pdbs : key => pdb.pdb_admin_password != null ? pdb.pdb_admin_password : try(base64decode(data.oci_secrets_secretbundle.additional_pdb_admin_password[key].secret_bundle_content[0].content), null)
  }

  db_system_compartment_ids = {
    for key, db_system in local.db_systems : key => try(
      db_system.compartment_id != null
      ? (length(regexall("^ocid1\\.", db_system.compartment_id)) > 0 ? db_system.compartment_id : var.compartments_dependency[db_system.compartment_id].id)
      : (length(regexall("^ocid1\\.", var.db_systems_configuration.default_compartment_id)) > 0 ? var.db_systems_configuration.default_compartment_id : var.compartments_dependency[var.db_systems_configuration.default_compartment_id].id),
      null
    )
  }

  db_system_subnet_ids = {
    for key, db_system in local.db_systems : key => try(
      length(regexall("^ocid1\\.", coalesce(db_system.subnet_id, var.db_systems_configuration.default_subnet_id))) > 0
      ? coalesce(db_system.subnet_id, var.db_systems_configuration.default_subnet_id)
      : var.network_dependency.subnets[coalesce(db_system.subnet_id, var.db_systems_configuration.default_subnet_id)].id,
      null
    )
  }

  db_system_nsg_ids = {
    for key, db_system in local.db_systems : key => [
      for nsg in db_system.nsg_ids : try(
        length(regexall("^ocid1\\.", nsg)) > 0
        ? nsg
        : var.network_dependency.network_security_groups[nsg].id,
        null
      )
    ]
  }

  db_system_kms_key_ids = {
    for key, db_system in local.db_systems : key => db_system.kms_key_id == null ? null : try(
      length(regexall("^ocid1\\.", db_system.kms_key_id)) > 0
      ? db_system.kms_key_id
      : var.kms_dependency[db_system.kms_key_id].id,
      null
    )
  }

  db_system_kms_key_version_ids = {
    for key, db_system in local.db_systems : key => db_system.kms_key_version_id
  }

  oracle_recovery_policy_keys = toset([
    for db_system in values(local.db_systems) : lower(try(db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id, ""))
    if try(db_system.db_home.database.db_backup_config.backup_destination_details.type, null) == "DBRS" && contains(
      ["bronze", "silver", "gold", "platinum"],
      lower(try(db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id, ""))
    )
  ])

  recovery_service_protection_policies = merge(
    try({ for key, policy in var.recovery_service_dependency : key => policy }, {}),
    try({ for key, policy in var.recovery_service_dependency.protection_policies : key => policy }, {})
  )

  db_system_dbrs_policy_ids = {
    for key, db_system in local.db_systems : key => try(
      can(regex("^ocid1\\.recoveryservicepolicy\\.", db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id)) ? db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id : try(
        local.recovery_service_protection_policies[db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id].id,
        data.oci_recovery_protection_policies.oracle_managed[lower(db_system.db_home.database.db_backup_config.backup_destination_details.dbrs_policy_id)].protection_policy_collection[0].items[0].id
      ),
      null
    )
    if try(db_system.db_home.database.db_backup_config.backup_destination_details.type, null) == "DBRS"
  }

  secret_ids = {
    for key in keys(local.db_systems) : key => (
      can(regex("^ocid1\\.vaultsecret\\.", trimspace(local.db_systems[key].db_home.database.admin_password_secret_id)))
      ? trimspace(local.db_systems[key].db_home.database.admin_password_secret_id)
      : try(var.secrets_dependency[trimspace(local.db_systems[key].db_home.database.admin_password_secret_id)].id, null)
    )
    if !try(length(local.db_systems[key].db_home.database.admin_password) > 0, false) && try(length(trimspace(local.db_systems[key].db_home.database.admin_password_secret_id)) > 0, false) && (
      can(regex("^ocid1\\.vaultsecret\\.", trimspace(local.db_systems[key].db_home.database.admin_password_secret_id))) || try(var.secrets_dependency[trimspace(local.db_systems[key].db_home.database.admin_password_secret_id)].id, null) != null
    )
  }

  # The CDB password is also the default TDE wallet password for additional PDB creation.
  db_system_container_passwords = {
    for key, db_system in local.db_systems : key => sensitive(
      try(length(db_system.db_home.database.admin_password) > 0, false)
      ? db_system.db_home.database.admin_password
      : try(base64decode(data.oci_secrets_secretbundle.admin_password[key].secret_bundle_content[0].content), null)
    )
  }
}
