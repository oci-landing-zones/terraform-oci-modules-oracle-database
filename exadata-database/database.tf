# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create Container Databases (CDB) with an initial Pluggable Database (PDB)
# - Uses a DB Home created by this Terraform stack (by key) or an explicitly provided DB Home OCID.

locals {
  legacy_database_defaults = {
    admin_password                         = null
    backup_id                              = null
    backup_tde_password                    = null
    character_set                          = null
    database_admin_password                = null
    database_id                            = null
    database_software_image_id             = null
    db_backup_config                       = null
    db_name                                = null
    db_unique_name                         = null
    db_workload                            = null
    defined_tags                           = null
    encryption_key_location_details        = null
    freeform_tags                          = null
    is_active_data_guard_enabled           = null
    key_store_id                           = null
    kms_key_id                             = null
    kms_key_version_id                     = null
    ncharacter_set                         = null
    pdb_name                               = null
    pluggable_databases                    = null
    protection_mode                        = null
    sid_prefix                             = null
    source_database_id                     = null
    source_encryption_key_location_details = null
    source_tde_wallet_password             = null
    tde_wallet_password                    = null
    time_stamp_for_point_in_time_recovery  = null
    transport_type                         = null
    vault_id                               = null
  }

  legacy_database_db_backup_config_defaults = {
    auto_backup_enabled        = null
    auto_backup_window         = null
    auto_full_backup_day       = null
    auto_full_backup_window    = null
    backup_deletion_policy     = null
    backup_destination_details = null
    recovery_window_in_days    = null
    run_immediate_full_backup  = null
  }

  legacy_database_backup_destination_details_defaults = {
    dbrs_policy_id = null
    id             = null
    is_remote      = null
    remote_region  = null
    type           = null
    vpc_password   = null
    vpc_user       = null
  }

  legacy_database_encryption_key_location_details_defaults = {
    provider_type           = null
    azure_encryption_key_id = null
    hsm_password            = null
  }

  legacy_cloud_db_home_database_entries = flatten([
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : [
      for database_key, database in coalesce(dbhome.database, {}) : {
        dbhome_key         = dbhome_key
        database_key       = database_key
        database           = database
        db_home_id         = dbhome_key
        source             = database.backup_id == null ? "NONE" : "DB_BACKUP"
        key_store_id       = database.key_store_id
        db_version         = dbhome.db_version
        kms_key_id         = database.kms_key_id
        kms_key_version_id = database.kms_key_version_id
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

  legacy_database_db_backup_configs = {
    for key, db in local.legacy_cloud_db_home_database_configs :
    key => try(values(db.database.db_backup_config)[0], null)
  }

  legacy_database_backup_destination_details = {
    for key, db_backup_config in local.legacy_database_db_backup_configs :
    key => try(values(db_backup_config.backup_destination_details)[0], null)
  }

  legacy_database_encryption_key_location_details = {
    for key, db in local.legacy_cloud_db_home_database_configs :
    key => try(values(db.database.encryption_key_location_details)[0], null)
  }

  legacy_database_source_encryption_key_location_details = {
    for key, db in local.legacy_cloud_db_home_database_configs :
    key => try(values(db.database.source_encryption_key_location_details)[0], null)
  }

  legacy_cloud_db_home_databases = {
    for key, db in local.legacy_cloud_db_home_database_configs :
    key => merge(db, {
      database = merge(local.legacy_database_defaults, db.database, {
        db_backup_config = local.legacy_database_db_backup_configs[key] == null ? null : merge(local.legacy_database_db_backup_config_defaults, local.legacy_database_db_backup_configs[key], {
          backup_destination_details = local.legacy_database_backup_destination_details[key] == null ? null : merge(local.legacy_database_backup_destination_details_defaults, local.legacy_database_backup_destination_details[key])
        })
        encryption_key_location_details = local.legacy_database_encryption_key_location_details[key] == null ? null : merge(local.legacy_database_encryption_key_location_details_defaults, local.legacy_database_encryption_key_location_details[key])
        source_encryption_key_location_details = local.legacy_database_source_encryption_key_location_details[key] == null ? null : merge(
          local.legacy_database_encryption_key_location_details_defaults,
          local.legacy_database_source_encryption_key_location_details[key]
        )
      })
    })
  }

  explicit_databases_configuration      = coalesce(var.databases_configuration, {})
  database_configuration_key_collisions = setintersection(toset(keys(local.legacy_cloud_db_home_databases)), toset(keys(local.explicit_databases_configuration)))
  effective_databases_configuration     = merge(local.legacy_cloud_db_home_databases, local.explicit_databases_configuration)

  database_key_store_ids = {
    for key, db in local.effective_databases_configuration :
    key => try(coalesce(try(db.key_store_id, null), try(db.database.key_store_id, null)), null)
  }

  database_kms_key_ids = {
    for key, db in local.effective_databases_configuration :
    key => try(coalesce(try(db.kms_key_id, null), try(db.database.kms_key_id, null)), null)
  }

  database_kms_key_version_ids = {
    for key, db in local.effective_databases_configuration :
    key => try(coalesce(try(db.kms_key_version_id, null), try(db.database.kms_key_version_id, null)), null)
  }

  recovery_service_protection_policies = merge(
    try({ for key, policy in var.recovery_service_dependency : key => policy }, {}),
    try({ for key, policy in var.recovery_service_dependency.protection_policies : key => policy }, {})
  )

  database_dbrs_policy_ids = {
    for key, db in local.effective_databases_configuration :
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
    for key, db in local.effective_databases_configuration :
    key => merge(db, {
      # Resolve DB Home: use as-is if OCID, or reference created DB Home by key
      db_home_id_input         = db.db_home_id
      kms_key_id_input         = local.database_kms_key_ids[key]
      source_database_id_input = try(db.database.source_database_id, null)
      dbrs_policy_id_input     = local.database_dbrs_policy_ids[key]
      db_home_id               = can(regex("^ocid1\\.dbhome\\.", db.db_home_id)) ? db.db_home_id : try(oci_database_db_home.these[db.db_home_id].id, var.exadata_database_dependency.database_homes[db.db_home_id].id, null)
      admin_password           = db.database.admin_password
      tde_wallet_password      = try(db.database.tde_wallet_password, null)
      pdb_admin_password       = try(db.database.pdb_admin_password, db.database.admin_password)
      key_store_id             = local.database_key_store_ids[key]
      kms_key_id               = can(regex("^ocid1\\.", local.database_kms_key_ids[key])) ? local.database_kms_key_ids[key] : try(var.kms_dependency[local.database_kms_key_ids[key]].id, null)
      kms_key_version_id       = local.database_kms_key_version_ids[key]
      source_database_id       = can(regex("^ocid1\\.database\\.", try(db.database.source_database_id, null))) ? db.database.source_database_id : try(var.exadata_database_dependency.databases[db.database.source_database_id].id, null)
      dbrs_policy_id           = local.database_resolved_dbrs_policy_ids[key]

      # Tag defaults
      defined_tags  = coalesce(try(db.database.defined_tags, null), var.default_defined_tags)
      freeform_tags = coalesce(try(db.database.freeform_tags, null), var.default_freeform_tags)
    })
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
    admin_password = sensitive(each.value.admin_password)
    db_name        = each.value.database.db_name
    #optional
    backup_id                  = each.value.database.backup_id           #<<Optional value>>
    backup_tde_password        = each.value.database.backup_tde_password #<<Required when source=DB_BACKUP>>
    character_set              = try(each.value.database.character_set, null)
    database_admin_password    = each.value.database.database_admin_password    #<<Required when source=DATAGUARD>>
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
            vpc_password   = backup_destination_details.value.vpc_password
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
        hsm_password            = encryption_key_location_details.value.hsm_password            #<<The password of the HSM user.>>
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
    source_tde_wallet_password = sensitive(try(each.value.database.source_tde_wallet_password, null))
    dynamic "source_encryption_key_location_details" {
      for_each = each.value.database.source_encryption_key_location_details != null ? [each.value.database.source_encryption_key_location_details] : []
      content {
        provider_type = source_encryption_key_location_details.value.provider_type
        hsm_password  = try(source_encryption_key_location_details.value.hsm_password, null) #<<The password of the HSM user.>>
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
      error_message = "db_home_id must be a DB Home OCID or a key in exadata_database_dependency.database_homes."
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
      error_message = "source_database_id must be a database OCID or a key in exadata_database_dependency.databases."
    }

    precondition {
      condition     = each.value.dbrs_policy_id_input == null ? true : (each.value.dbrs_policy_id != null && can(regex("^ocid1\\.", each.value.dbrs_policy_id)))
      error_message = "dbrs_policy_id must be an OCID or a key in recovery_service_dependency."
    }

    ignore_changes = [
      # Ignore changes to the following attributes after creation
      # These attributes are managed outside of Terraform and should not trigger updates
      db_home_id,
      db_version,
      database.0.admin_password,
      database.0.defined_tags
    ]
  }
}
