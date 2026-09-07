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
  cdb_backup_tde_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.backup_tde_password) > 0, false) ? db.database.backup_tde_password : try(base64decode(data.oci_secrets_secretbundle.cdb_backup_tde_password[key].secret_bundle_content[0].content), null))
  }
  cdb_dataguard_admin_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.database_admin_password) > 0, false) ? db.database.database_admin_password : try(base64decode(data.oci_secrets_secretbundle.cdb_dataguard_admin_password[key].secret_bundle_content[0].content), null))
  }
  cdb_backup_destination_vpc_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.db_backup_config.backup_destination_details.vpc_password) > 0, false) ? db.database.db_backup_config.backup_destination_details.vpc_password : try(base64decode(data.oci_secrets_secretbundle.cdb_backup_destination_vpc_password[key].secret_bundle_content[0].content), null))
  }
  cdb_encryption_hsm_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.encryption_key_location_details.hsm_password) > 0, false) ? db.database.encryption_key_location_details.hsm_password : try(base64decode(data.oci_secrets_secretbundle.cdb_encryption_hsm_password[key].secret_bundle_content[0].content), null))
  }
  cdb_source_tde_wallet_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.source_tde_wallet_password) > 0, false) ? db.database.source_tde_wallet_password : try(base64decode(data.oci_secrets_secretbundle.cdb_source_tde_wallet_password[key].secret_bundle_content[0].content), null))
  }
  cdb_source_encryption_hsm_passwords = {
    for key, db in coalesce(var.databases_configuration, {}) : key => sensitive(try(length(db.database.source_encryption_key_location_details["hsm_password"]) > 0, false) ? db.database.source_encryption_key_location_details["hsm_password"] : try(base64decode(data.oci_secrets_secretbundle.cdb_source_encryption_hsm_password[key].secret_bundle_content[0].content), null))
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
      db_home_id_input               = db.db_home_id
      kms_key_id_input               = local.database_kms_key_ids[key]
      source_database_id_input       = try(db.database.source_database_id, null)
      dbrs_policy_id_input           = local.database_dbrs_policy_ids[key]
      db_home_id                     = can(regex("^ocid1\\.dbhome\\.", db.db_home_id)) ? db.db_home_id : try(oci_database_db_home.these[db.db_home_id].id, var.database_dependency.database_homes[db.db_home_id].id, null)
      admin_password                 = local.cdb_admin_passwords[key]
      backup_tde_password            = local.cdb_backup_tde_passwords[key]
      database_admin_password        = local.cdb_dataguard_admin_passwords[key]
      backup_vpc_password            = local.cdb_backup_destination_vpc_passwords[key]
      encryption_hsm_password        = local.cdb_encryption_hsm_passwords[key]
      source_tde_wallet_password     = local.cdb_source_tde_wallet_passwords[key]
      source_encryption_hsm_password = local.cdb_source_encryption_hsm_passwords[key]
      tde_wallet_password            = local.cdb_tde_wallet_passwords[key]
      pdb_admin_password             = try(db.database.pdb_admin_password, local.cdb_admin_passwords[key])
      key_store_id                   = local.database_key_store_ids[key]
      kms_key_id                     = can(regex("^ocid1\\.", local.database_kms_key_ids[key])) ? local.database_kms_key_ids[key] : try(var.kms_dependency[local.database_kms_key_ids[key]].id, null)
      kms_key_version_id             = local.database_kms_key_version_ids[key]
      source_database_id             = can(regex("^ocid1\\.database\\.", try(db.database.source_database_id, null))) ? db.database.source_database_id : try(var.database_dependency.databases[db.database.source_database_id].id, null)
      dbrs_policy_id                 = local.database_resolved_dbrs_policy_ids[key]

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
  # Strip sensitivity for iteration keys; values remain sensitive in use.
  for_each = local.databases

  #Required
  source     = each.value.source
  db_home_id = each.value.db_home_id
  database {
    #Required
    admin_password = each.value.admin_password
    db_name        = each.value.database.db_name
    #optional
    backup_id                  = each.value.database.backup_id  #<<Optional value>>
    backup_tde_password        = each.value.backup_tde_password #<<Required when source=DB_BACKUP>>
    character_set              = try(each.value.database.character_set, null)
    database_admin_password    = each.value.database_admin_password             #<<Required when source=DATAGUARD>>
    database_id                = each.value.database.database_id                #<<Applicable for point-in-time recovery>>
    database_software_image_id = each.value.database.database_software_image_id #<<Optional value>>
    dynamic "db_backup_config" {
      for_each = each.value.database.db_backup_config != null ? [each.value.database.db_backup_config] : []
      content {
        auto_backup_enabled     = db_backup_config.value.auto_backup_enabled
        auto_backup_window      = db_backup_config.value.auto_backup_window      #<<If no option is selected, a start time between 12:00 AM to 7:00 AM in the region of the database is automatically chosen.>>
        auto_full_backup_day    = db_backup_config.value.auto_full_backup_day    #<<If no option is selected, the value is null and we will default to Sunday.>>
        auto_full_backup_window = db_backup_config.value.auto_full_backup_window #<<If no option is selected, a start time between 12:00 AM to 7:00 AM in the region of the database is automatically chosen.>>
        backup_deletion_policy  = db_backup_config.value.backup_deletion_policy
        dynamic "backup_destination_details" {
          for_each = each.value.database.db_backup_config.backup_destination_details != null ? [each.value.database.db_backup_config.backup_destination_details] : []
          content {
            dbrs_policy_id = each.value.dbrs_policy_id
            id             = backup_destination_details.value.id
            is_remote      = backup_destination_details.value.is_remote
            remote_region  = backup_destination_details.value.remote_region
            type           = backup_destination_details.value.type # The type must be one of: AWS_S3, DBRS, OBJECT_STORE, NFS, RECOVERY_APPLIANCE, LOCAL
            vpc_password   = each.value.backup_vpc_password
            vpc_user       = backup_destination_details.value.vpc_user
          }
        }
        recovery_window_in_days   = db_backup_config.value.recovery_window_in_days
        run_immediate_full_backup = db_backup_config.value.run_immediate_full_backup
      }
    }
    db_unique_name = each.value.database.db_unique_name
    db_workload    = each.value.database.db_workload
    defined_tags   = each.value.defined_tags
    dynamic "encryption_key_location_details" {
      for_each = each.value.database.encryption_key_location_details != null ? [each.value.database.encryption_key_location_details] : []
      content {
        provider_type           = encryption_key_location_details.value.provider_type
        azure_encryption_key_id = encryption_key_location_details.value.azure_encryption_key_id #<<The ID of the Azure Key Vault key.>>
        hsm_password            = each.value.encryption_hsm_password                            #<<The password of the HSM user.>>
      }
    }
    freeform_tags = each.value.freeform_tags
    #key_store_id = each.value.database.key_store_id #<<The OCID of the key store of Oracle Vault.>>
    is_active_data_guard_enabled = each.value.database.is_active_data_guard_enabled #<<Applicable when source=DATAGUARD>>
    kms_key_id                   = each.value.kms_key_id                            #<< The OCID of the key container that is used as the master encryption key in database transparent data encryption (TDE) operations.>>
    kms_key_version_id           = each.value.kms_key_version_id                    #<<The OCID of the key container version that is used in database transparent data encryption (TDE) operations KMS Key can have multiple key versions. If none is specified, the current key version (latest) of the Key Id is used for the operation.>>
    ncharacter_set               = each.value.database.ncharacter_set               #The default is AL16UTF16. Allowed values are: AL16UTF16 or UTF8.
    # Create initial PDB during CDB creation
    pdb_name                   = each.value.database.pdb_name            #The name must begin with an alphabetic character and can contain a maximum of thirty alphanumeric characters. Special characters are not permitted. Pl
    pluggable_databases        = each.value.database.pluggable_databases #<<(Applicable when source=DB_BACKUP) The list of pluggable databases that needs to be restored into new database.>>
    protection_mode            = each.value.database.protection_mode     #<<(Required when source=DATAGUARD) The protection mode of this Data Guard. >>
    sid_prefix                 = each.value.database.sid_prefix
    source_database_id         = each.value.source_database_id #<<(Required when source=DATAGUARD) The OCID of the source database.>>
    source_tde_wallet_password = each.value.source_tde_wallet_password
    dynamic "source_encryption_key_location_details" {
      for_each = each.value.database.source_encryption_key_location_details != null ? [each.value.database.source_encryption_key_location_details] : []
      content {
        provider_type = source_encryption_key_location_details.value.provider_type
        hsm_password  = each.value.source_encryption_hsm_password #<<The password of the HSM user.>>
      }
    }
    tde_wallet_password                   = sensitive(each.value.tde_wallet_password)
    time_stamp_for_point_in_time_recovery = each.value.database.time_stamp_for_point_in_time_recovery
    transport_type                        = each.value.database.transport_type #<<(Required when source=DATAGUARD) The redo transport type to use for this Data Guard association>>
    vault_id                              = each.value.database.vault_id       #<<(Applicable when source=NONE) The OCID of the Oracle Cloud Infrastructure vault. This parameter and secretId are required for Customer Managed Keys.>>
  }
  key_store_id       = each.value.key_store_id #<<The OCID of the key store of Oracle Vault.>>
  db_version         = each.value.db_version
  kms_key_id         = try(each.value.kms_key_id, null)
  kms_key_version_id = try(each.value.kms_key_version_id, null)

  lifecycle {
    precondition {
      condition     = each.value.db_home_id != null && can(regex("^ocid1\\.dbhome\\.", each.value.db_home_id))
      error_message = "db_home_id must be a DB Home OCID or a key in database_dependency.database_homes."
    }

    precondition {
      condition     = length(local.database_configuration_key_collisions) == 0
      error_message = "Database keys must be unique across cloud_db_homes_configuration[*].database and databases_configuration."
    }

    precondition {
      condition     = each.value.kms_key_id_input == null ? true : (each.value.kms_key_id != null && can(regex("^ocid1\\.", each.value.kms_key_id)))
      error_message = "kms_key_id must be an OCID or a key in kms_dependency."
    }

    precondition {
      condition     = each.value.source_database_id_input == null ? true : (each.value.source_database_id != null && can(regex("^ocid1\\.database\\.", each.value.source_database_id)))
      error_message = "source_database_id must be a database OCID or a key in database_dependency.databases."
    }

    precondition {
      condition     = each.value.dbrs_policy_id_input == null ? true : (each.value.dbrs_policy_id != null && can(regex("^ocid1\\.", each.value.dbrs_policy_id)))
      error_message = "dbrs_policy_id must be an OCID or a key in recovery_service_dependency."
    }

    precondition {
      condition = try(
        length(nonsensitive(each.value.admin_password)) >= 9 &&
        length(nonsensitive(each.value.admin_password)) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(each.value.admin_password))) &&
        length(regexall("[A-Z]", nonsensitive(each.value.admin_password))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(each.value.admin_password))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(each.value.admin_password))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(each.value.admin_password))) >= 2,
        false
      )
      error_message = "The resolved admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    precondition {
      condition = !try(length(each.value.database.tde_wallet_password) > 0, false) && local.cdb_tde_wallet_password_secret_id_inputs[each.key] == "" ? true : try(
        length(nonsensitive(each.value.tde_wallet_password)) >= 9 &&
        length(nonsensitive(each.value.tde_wallet_password)) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(each.value.tde_wallet_password))) &&
        length(regexall("[A-Z]", nonsensitive(each.value.tde_wallet_password))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(each.value.tde_wallet_password))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(each.value.tde_wallet_password))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(each.value.tde_wallet_password))) >= 2,
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
