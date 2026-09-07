# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create Container Databases (CDB) with an initial Pluggable Database (PDB)
# - Uses a DB Home created by this Terraform stack (by key) or an explicitly provided DB Home OCID.

locals {
  cdb_admin_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.admin_password_secret_id), "")
  }
  cdb_backup_tde_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.backup_tde_password_secret_id), "")
  }
  cdb_dataguard_admin_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.database_admin_password_secret_id), "")
  }
  cdb_backup_destination_vpc_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.db_backup_config.backup_destination_details.vpc_password_secret_id), "")
  }
  cdb_encryption_hsm_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.encryption_key_location_details.hsm_password_secret_id), "")
  }
  cdb_source_tde_wallet_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.source_tde_wallet_password_secret_id), "")
  }
  cdb_source_encryption_hsm_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.source_encryption_key_location_details["hsm_password_secret_id"]), "")
  }
  cdb_tde_wallet_password_secret_id_inputs = {
    for key, db in coalesce(var.databases_configuration, {}) : key => try(trimspace(db.database.tde_wallet_password_secret_id), "")
  }

  cdb_admin_password_secret_ids = {
    for key, secret_ref in local.cdb_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_backup_tde_password_secret_ids = {
    for key, secret_ref in local.cdb_backup_tde_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_dataguard_admin_password_secret_ids = {
    for key, secret_ref in local.cdb_dataguard_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_backup_destination_vpc_password_secret_ids = {
    for key, secret_ref in local.cdb_backup_destination_vpc_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_encryption_hsm_password_secret_ids = {
    for key, secret_ref in local.cdb_encryption_hsm_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_source_tde_wallet_password_secret_ids = {
    for key, secret_ref in local.cdb_source_tde_wallet_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_source_encryption_hsm_password_secret_ids = {
    for key, secret_ref in local.cdb_source_encryption_hsm_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  cdb_tde_wallet_password_secret_ids = {
    for key, secret_ref in local.cdb_tde_wallet_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }

  cdb_admin_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.admin_password) > 0, false) ? db.database.admin_password : try(base64decode(data.oci_secrets_secretbundle.cdb_admin_password[key].secret_bundle_content[0].content), null))
  }
  cdb_tde_wallet_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.tde_wallet_password) > 0, false) ? db.database.tde_wallet_password : try(base64decode(data.oci_secrets_secretbundle.cdb_tde_wallet_password[key].secret_bundle_content[0].content), null))
  }

  legacy_cloud_db_home_database_entries = flatten([
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : [
      for database_key, _database in coalesce(dbhome.database, {}) : {
        dbhome_key   = dbhome_key
        database_key = database_key
      }
    ]
  ])

  legacy_cloud_db_home_database_key_counts = {
    for database_key in toset([for entry in local.legacy_cloud_db_home_database_entries : entry.database_key]) :
    database_key => length([for entry in local.legacy_cloud_db_home_database_entries : entry.database_key if entry.database_key == database_key])
  }

  legacy_cloud_db_home_database_configs = {
    for entry in local.legacy_cloud_db_home_database_entries :
    local.legacy_cloud_db_home_database_key_counts[entry.database_key] == 1 ? entry.database_key : "${entry.dbhome_key}.${entry.database_key}" => entry
  }

  explicit_databases_configuration      = coalesce(var.databases_configuration, {})
  database_configuration_key_collisions = setintersection(toset(keys(local.legacy_cloud_db_home_database_configs)), toset(keys(local.explicit_databases_configuration)))

  database_key_store_ids = {
    for key, db in local.explicit_databases_configuration :
    key => try(coalesce(try(db.key_store_id, null), try(db.database.key_store_id, null)), null)
  }

  database_kms_key_ids = {
    for key, db in local.explicit_databases_configuration :
    key => try(coalesce(try(db.kms_key_id, null), try(db.database.kms_key_id, null)), null)
  }

  database_kms_key_version_ids = {
    for key, db in local.explicit_databases_configuration :
    key => try(coalesce(try(db.kms_key_version_id, null), try(db.database.kms_key_version_id, null)), null)
  }

  recovery_service_protection_policies = merge(
    try({ for key, policy in var.recovery_service_dependency : key => policy }, {}),
    try({ for key, policy in var.recovery_service_dependency.protection_policies : key => policy }, {})
  )

  database_dbrs_policy_ids = {
    for key, db in local.explicit_databases_configuration :
    key => try(db.database.db_backup_config.backup_destination_details.dbrs_policy_id, null)
  }

  database_resolved_dbrs_policy_ids = {
    for key, dbrs_policy_id in local.database_dbrs_policy_ids :
    key => dbrs_policy_id == null ? null : (
      can(regex("^ocid1\\.", dbrs_policy_id))
      ? dbrs_policy_id
      : try(local.recovery_service_protection_policies[dbrs_policy_id].id, null)
    )
  }

  # Resolve references and defaults for database creation
  databases = {
    for key, db in local.explicit_databases_configuration :
    key => merge(db, {
      # Resolve DB Home: use as-is if OCID, or reference created DB Home by key
      db_home_id_input         = db.db_home_id
      kms_key_id_input         = local.database_kms_key_ids[key]
      source_database_id_input = try(db.database.source_database_id, null)
      dbrs_policy_id_input     = local.database_dbrs_policy_ids[key]
      db_home_id               = can(regex("^ocid1\\.dbhome\\.", db.db_home_id)) ? db.db_home_id : try(oci_database_db_home.these[db.db_home_id].id, var.database_dependency.database_homes[db.db_home_id].id, null)
      key_store_id             = local.database_key_store_ids[key]
      kms_key_id               = can(regex("^ocid1\\.", local.database_kms_key_ids[key])) ? local.database_kms_key_ids[key] : try(var.kms_dependency[local.database_kms_key_ids[key]].id, null)
      kms_key_version_id       = local.database_kms_key_version_ids[key]
      source_database_id       = can(regex("^ocid1\\.database\\.", try(db.database.source_database_id, null))) ? db.database.source_database_id : try(var.database_dependency.databases[db.database.source_database_id].id, null)
      dbrs_policy_id           = local.database_resolved_dbrs_policy_ids[key]

      # Tag defaults
      defined_tags  = coalesce(try(db.database.defined_tags, null), var.default_defined_tags)
      freeform_tags = coalesce(try(db.database.freeform_tags, null), var.default_freeform_tags)
    })
  }
}

data "oci_secrets_secretbundle" "cdb_admin_password" {
  for_each  = { for key, ref in local.cdb_admin_password_secret_id_inputs : key => local.cdb_admin_password_secret_ids[key] if ref != "" }
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
data "oci_secrets_secretbundle" "cdb_backup_tde_password" {
  for_each  = { for key, ref in local.cdb_backup_tde_password_secret_id_inputs : key => local.cdb_backup_tde_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "backup_tde_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current backup TDE password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_dataguard_admin_password" {
  for_each  = { for key, ref in local.cdb_dataguard_admin_password_secret_id_inputs : key => local.cdb_dataguard_admin_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "database_admin_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current Data Guard admin password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_backup_destination_vpc_password" {
  for_each  = { for key, ref in local.cdb_backup_destination_vpc_password_secret_id_inputs : key => local.cdb_backup_destination_vpc_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "vpc_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current VPC password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_encryption_hsm_password" {
  for_each  = { for key, ref in local.cdb_encryption_hsm_password_secret_id_inputs : key => local.cdb_encryption_hsm_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "hsm_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current HSM password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_source_tde_wallet_password" {
  for_each  = { for key, ref in local.cdb_source_tde_wallet_password_secret_id_inputs : key => local.cdb_source_tde_wallet_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "source_tde_wallet_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current source TDE wallet password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_source_encryption_hsm_password" {
  for_each  = { for key, ref in local.cdb_source_encryption_hsm_password_secret_id_inputs : key => local.cdb_source_encryption_hsm_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "source hsm_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current source HSM password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "cdb_tde_wallet_password" {
  for_each  = { for key, ref in local.cdb_tde_wallet_password_secret_id_inputs : key => local.cdb_tde_wallet_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "tde_wallet_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current TDE wallet password secret content must be nonempty valid Base64."
    }
  }
}

# Create the CDB and its initial PDB via oci_database_database.
# Note: When specifying pdb_name in the 'database' block, Oracle will create the initial PDB along with the CDB.
# The admin_password must conform to the strong policy and is reused for SYS/SYSTEM and the default PDB Admin password.
resource "oci_database_database" "these" {
  # Match the ARS pattern: establish resource identity from the original
  # configuration and resolve sensitive passwords in resource attributes.
  for_each = coalesce(var.databases_configuration, {})

  #Required
  source     = local.databases[each.key].source
  db_home_id = local.databases[each.key].db_home_id
  database {
    #Required
    admin_password = sensitive(
      try(length(each.value.database.admin_password) > 0, false)
      ? each.value.database.admin_password
      : try(base64decode(data.oci_secrets_secretbundle.cdb_admin_password[each.key].secret_bundle_content[0].content), null)
    )
    db_name = local.databases[each.key].database.db_name
    #optional
    backup_id = local.databases[each.key].database.backup_id #<<Optional value>>
    backup_tde_password = sensitive(
      try(length(each.value.database.backup_tde_password) > 0, false)
      ? each.value.database.backup_tde_password
      : try(base64decode(data.oci_secrets_secretbundle.cdb_backup_tde_password[each.key].secret_bundle_content[0].content), null)
    ) #<<Required when source=DB_BACKUP>>
    character_set = try(local.databases[each.key].database.character_set, null)
    database_admin_password = sensitive(
      try(length(each.value.database.database_admin_password) > 0, false)
      ? each.value.database.database_admin_password
      : try(base64decode(data.oci_secrets_secretbundle.cdb_dataguard_admin_password[each.key].secret_bundle_content[0].content), null)
    )                                                                                          #<<Required when source=DATAGUARD>>
    database_id                = local.databases[each.key].database.database_id                #<<Applicable for point-in-time recovery>>
    database_software_image_id = local.databases[each.key].database.database_software_image_id #<<Optional value>>
    dynamic "db_backup_config" {
      for_each = local.databases[each.key].database.db_backup_config != null ? [local.databases[each.key].database.db_backup_config] : []
      content {
        auto_backup_enabled     = db_backup_config.value.auto_backup_enabled
        auto_backup_window      = db_backup_config.value.auto_backup_window      #<<If no option is selected, a start time between 12:00 AM to 7:00 AM in the region of the database is automatically chosen.>>
        auto_full_backup_day    = db_backup_config.value.auto_full_backup_day    #<<If no option is selected, the value is null and we will default to Sunday.>>
        auto_full_backup_window = db_backup_config.value.auto_full_backup_window #<<If no option is selected, a start time between 12:00 AM to 7:00 AM in the region of the database is automatically chosen.>>
        backup_deletion_policy  = db_backup_config.value.backup_deletion_policy
        dynamic "backup_destination_details" {
          for_each = local.databases[each.key].database.db_backup_config.backup_destination_details != null ? [local.databases[each.key].database.db_backup_config.backup_destination_details] : []
          content {
            dbrs_policy_id = local.databases[each.key].dbrs_policy_id
            id             = backup_destination_details.value.id
            is_remote      = backup_destination_details.value.is_remote
            remote_region  = backup_destination_details.value.remote_region
            type           = backup_destination_details.value.type # The type must be one of: AWS_S3, DBRS, OBJECT_STORE, NFS, RECOVERY_APPLIANCE, LOCAL
            vpc_password = sensitive(
              try(length(each.value.database.db_backup_config.backup_destination_details.vpc_password) > 0, false)
              ? each.value.database.db_backup_config.backup_destination_details.vpc_password
              : try(base64decode(data.oci_secrets_secretbundle.cdb_backup_destination_vpc_password[each.key].secret_bundle_content[0].content), null)
            )
            vpc_user = backup_destination_details.value.vpc_user
          }
        }
        recovery_window_in_days   = db_backup_config.value.recovery_window_in_days
        run_immediate_full_backup = db_backup_config.value.run_immediate_full_backup
      }
    }
    db_unique_name = local.databases[each.key].database.db_unique_name
    db_workload    = local.databases[each.key].database.db_workload
    defined_tags   = local.databases[each.key].defined_tags
    dynamic "encryption_key_location_details" {
      for_each = local.databases[each.key].database.encryption_key_location_details != null ? [local.databases[each.key].database.encryption_key_location_details] : []
      content {
        provider_type           = encryption_key_location_details.value.provider_type
        azure_encryption_key_id = encryption_key_location_details.value.azure_encryption_key_id #<<The ID of the Azure Key Vault key.>>
        hsm_password = sensitive(
          try(length(each.value.database.encryption_key_location_details.hsm_password) > 0, false)
          ? each.value.database.encryption_key_location_details.hsm_password
          : try(base64decode(data.oci_secrets_secretbundle.cdb_encryption_hsm_password[each.key].secret_bundle_content[0].content), null)
        ) #<<The password of the HSM user.>>
      }
    }
    freeform_tags = local.databases[each.key].freeform_tags
    #key_store_id = local.databases[each.key].database.key_store_id #<<The OCID of the key store of Oracle Vault.>>
    is_active_data_guard_enabled = local.databases[each.key].database.is_active_data_guard_enabled #<<Applicable when source=DATAGUARD>>
    kms_key_id                   = local.databases[each.key].kms_key_id                            #<< The OCID of the key container that is used as the master encryption key in database transparent data encryption (TDE) operations.>>
    kms_key_version_id           = local.databases[each.key].kms_key_version_id                    #<<The OCID of the key container version that is used in database transparent data encryption (TDE) operations KMS Key can have multiple key versions. If none is specified, the current key version (latest) of the Key Id is used for the operation.>>
    ncharacter_set               = local.databases[each.key].database.ncharacter_set               #The default is AL16UTF16. Allowed values are: AL16UTF16 or UTF8.
    # Create initial PDB during CDB creation
    pdb_name            = local.databases[each.key].database.pdb_name            #The name must begin with an alphabetic character and can contain a maximum of thirty alphanumeric characters. Special characters are not permitted. Pl
    pluggable_databases = local.databases[each.key].database.pluggable_databases #<<(Applicable when source=DB_BACKUP) The list of pluggable databases that needs to be restored into new database.>>
    protection_mode     = local.databases[each.key].database.protection_mode     #<<(Required when source=DATAGUARD) The protection mode of this Data Guard. >>
    sid_prefix          = local.databases[each.key].database.sid_prefix
    source_database_id  = local.databases[each.key].source_database_id #<<(Required when source=DATAGUARD) The OCID of the source database.>>
    source_tde_wallet_password = sensitive(
      try(length(each.value.database.source_tde_wallet_password) > 0, false)
      ? each.value.database.source_tde_wallet_password
      : try(base64decode(data.oci_secrets_secretbundle.cdb_source_tde_wallet_password[each.key].secret_bundle_content[0].content), null)
    )
    dynamic "source_encryption_key_location_details" {
      for_each = local.databases[each.key].database.source_encryption_key_location_details != null ? [local.databases[each.key].database.source_encryption_key_location_details] : []
      content {
        provider_type = source_encryption_key_location_details.value.provider_type
        hsm_password = sensitive(
          try(length(each.value.database.source_encryption_key_location_details["hsm_password"]) > 0, false)
          ? each.value.database.source_encryption_key_location_details["hsm_password"]
          : try(base64decode(data.oci_secrets_secretbundle.cdb_source_encryption_hsm_password[each.key].secret_bundle_content[0].content), null)
        ) #<<The password of the HSM user.>>
      }
    }
    tde_wallet_password = sensitive(
      try(length(each.value.database.tde_wallet_password) > 0, false)
      ? each.value.database.tde_wallet_password
      : try(base64decode(data.oci_secrets_secretbundle.cdb_tde_wallet_password[each.key].secret_bundle_content[0].content), null)
    )
    time_stamp_for_point_in_time_recovery = local.databases[each.key].database.time_stamp_for_point_in_time_recovery
    transport_type                        = local.databases[each.key].database.transport_type #<<(Required when source=DATAGUARD) The redo transport type to use for this Data Guard association>>
    vault_id                              = local.databases[each.key].database.vault_id       #<<(Applicable when source=NONE) The OCID of the Oracle Cloud Infrastructure vault. This parameter and secretId are required for Customer Managed Keys.>>
  }
  key_store_id       = local.databases[each.key].key_store_id #<<The OCID of the key store of Oracle Vault.>>
  db_version         = local.databases[each.key].db_version
  kms_key_id         = try(local.databases[each.key].kms_key_id, null)
  kms_key_version_id = try(local.databases[each.key].kms_key_version_id, null)

  lifecycle {
    precondition {
      condition     = local.databases[each.key].db_home_id != null && can(regex("^ocid1\\.dbhome\\.", local.databases[each.key].db_home_id))
      error_message = "db_home_id must be a DB Home OCID or a key in database_dependency.database_homes."
    }

    precondition {
      condition     = length(local.database_configuration_key_collisions) == 0
      error_message = "Database keys must be unique across cloud_db_homes_configuration[*].database and databases_configuration."
    }

    precondition {
      condition     = local.databases[each.key].kms_key_id_input == null ? true : (local.databases[each.key].kms_key_id != null && can(regex("^ocid1\\.", local.databases[each.key].kms_key_id)))
      error_message = "kms_key_id must be an OCID or a key in kms_dependency."
    }

    precondition {
      condition     = local.databases[each.key].source_database_id_input == null ? true : (local.databases[each.key].source_database_id != null && can(regex("^ocid1\\.database\\.", local.databases[each.key].source_database_id)))
      error_message = "source_database_id must be a database OCID or a key in database_dependency.databases."
    }

    precondition {
      condition     = local.databases[each.key].dbrs_policy_id_input == null ? true : (local.databases[each.key].dbrs_policy_id != null && can(regex("^ocid1\\.", local.databases[each.key].dbrs_policy_id)))
      error_message = "dbrs_policy_id must be an OCID or a key in recovery_service_dependency."
    }

    precondition {
      condition = try(
        length(nonsensitive(local.cdb_admin_passwords[each.key])) >= 9 &&
        length(nonsensitive(local.cdb_admin_passwords[each.key])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.cdb_admin_passwords[each.key]))) &&
        length(regexall("[A-Z]", nonsensitive(local.cdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.cdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.cdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.cdb_admin_passwords[each.key]))) >= 2,
        false
      )
      error_message = "The resolved admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    precondition {
      condition = !try(length(local.databases[each.key].database.tde_wallet_password) > 0, false) && local.cdb_tde_wallet_password_secret_id_inputs[each.key] == "" ? true : try(
        length(nonsensitive(local.cdb_tde_wallet_passwords[each.key])) >= 9 &&
        length(nonsensitive(local.cdb_tde_wallet_passwords[each.key])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.cdb_tde_wallet_passwords[each.key]))) &&
        length(regexall("[A-Z]", nonsensitive(local.cdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.cdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.cdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.cdb_tde_wallet_passwords[each.key]))) >= 2,
        false
      )
      error_message = "The resolved TDE wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    ignore_changes = [
      # Ignore changes to the following attributes after creation.
      # These attributes are managed outside Terraform or should not trigger updates.
      db_home_id,
      db_version,
      database.0.admin_password,
      database.0.backup_tde_password,
      database.0.source_tde_wallet_password,
      database.0.tde_wallet_password,
      database.0.defined_tags["Oracle-Tags.CreatedBy"],
      database.0.defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}
