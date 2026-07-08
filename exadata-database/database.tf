# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Create Container Databases (CDB) with an initial Pluggable Database (PDB)
# - Uses a DB Home created by this Terraform stack (by key) or an explicitly provided DB Home OCID.

locals {
  recovery_service_protection_policies = merge(
    try({ for key, policy in var.recovery_service_dependency : key => policy }, {}),
    try({ for key, policy in var.recovery_service_dependency.protection_policies : key => policy }, {})
  )

  # Resolve references and defaults for database creation
  databases = {
    for key, db in coalesce(var.databases_configuration, {}) :
    key => merge(db, {
      # Resolve DB Home: use as-is if OCID, or reference created DB Home by key
      db_home_id          = can(regex("^ocid1\\.dbhome\\.", db.db_home_id)) ? db.db_home_id : try(oci_database_db_home.these[db.db_home_id].id, null)
      admin_password      = db.database.admin_password
      tde_wallet_password = try(db.database.tde_wallet_password, db.database.admin_password)
      pdb_admin_password  = try(db.database.pdb_admin_password, db.database.admin_password)

      # Tag defaults
      defined_tags  = try(db.defined_tags, var.default_defined_tags)
      freeform_tags = try(db.freeform_tags, var.default_freeform_tags)
    })
  }
}

# Create the CDB and its initial PDB via oci_database_database.
# Note: When specifying pdb_name in the 'database' block, Oracle will create the initial PDB along with the CDB.
# The admin_password must conform to the strong policy and is reused for SYS/SYSTEM, TDE wallet, and PDB Admin
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
            dbrs_policy_id = backup_destination_details.value.dbrs_policy_id == null ? null : (can(regex("^ocid1\\.", backup_destination_details.value.dbrs_policy_id)) ? backup_destination_details.value.dbrs_policy_id : local.recovery_service_protection_policies[backup_destination_details.value.dbrs_policy_id].id)
            id             = backup_destination_details.value.id
            is_remote      = backup_destination_details.value.is_remote
            remote_region  = backup_destination_details.value.remote_region
            type           = backup_destination_details.value.type # The type must be one of: NFS, RECOVERY_APPLIANCE, BRITECONNECT, OBJECT_STORAGE
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
    pdb_name            = each.value.database.pdb_name            #The name must begin with an alphabetic character and can contain a maximum of thirty alphanumeric characters. Special characters are not permitted. Pl
    pluggable_databases = each.value.database.pluggable_databases #<<(Applicable when source=DB_BACKUP) The list of pluggable databases that needs to be restored into new database.>>
    protection_mode     = each.value.database.protection_mode     #<<(Required when source=DATAGUARD) The protection mode of this Data Guard. >>
    sid_prefix          = each.value.database.sid_prefix
    source_database_id  = each.value.database.source_database_id #<<(Required when source=DATAGUARD) The OCID of the source database.>>
    dynamic "source_encryption_key_location_details" {
      for_each = each.value.database.source_encryption_key_location_details != null ? [each.value.database.source_encryption_key_location_details] : []
      content {
        provider_type = source_encryption_key_location_details.value.provider_type
        #azure_encryption_key_id = source_encryption_key_location_details.value.azure_encryption_key_id #<<The ID of the Azure Key Vault key.>>
        hsm_password = source_encryption_key_location_details.value.hsm_password #<<The password of the HSM user.>>
      }
    }
    tde_wallet_password = sensitive(each.value.tde_wallet_password)
    transport_type      = each.value.database.transport_type #<<(Required when source=DATAGUARD) The redo transport type to use for this Data Guard association>>
    vault_id            = each.value.database.vault_id       #<<(Applicable when source=NONE) The OCID of the Oracle Cloud Infrastructure vault. This parameter and secretId are required for Customer Managed Keys.>> 
  }
  key_store_id       = each.value.key_store_id #<<The OCID of the key store of Oracle Vault.>>
  db_version         = each.value.db_version
  kms_key_id         = try(each.value.kms_key_id, null)
  kms_key_version_id = try(each.value.kms_key_version_id, null)

  lifecycle {
    ignore_changes = [
      # Ignore changes to the following attributes after creation
      # These attributes are managed outside of Terraform and should not trigger updates
      db_home_id,
      db_version,
      database.0.admin_password
    ]
  }
}
