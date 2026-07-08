# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  cloud_db_homes = {
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) :
    dbhome_key => merge(dbhome, {
      # Resolve VM Cluster ID: use as-is if OCID, or reference created VM cluster by key
      vm_cluster_id = can(regex("^ocid1\\.", dbhome.vm_cluster_id)) ? dbhome.vm_cluster_id : try(oci_database_cloud_vm_cluster.these[dbhome.vm_cluster_id].id, null)
    })
  }
}

resource "oci_database_db_home" "these" {
  depends_on = [oci_database_cloud_vm_cluster.these]

  for_each = local.cloud_db_homes

  # ----------------------------
  # Required / core attributes
  # ----------------------------
  display_name  = each.value.display_name
  db_version    = each.value.db_version
  source        = each.value.source
  vm_cluster_id = lookup(each.value, "vm_cluster_id", null)
  db_system_id  = lookup(each.value, "db_system_id", null)

  # ----------------------------
  # Optional metadata / config
  # ----------------------------
  database_software_image_id  = lookup(each.value, "database_software_image_id", null)
  enable_database_delete      = lookup(each.value, "enable_database_delete", null)
  is_desupported_version      = lookup(each.value, "is_desupported_version", null)
  is_unified_auditing_enabled = lookup(each.value, "is_unified_auditing_enabled", null)
  kms_key_id                  = lookup(each.value, "kms_key_id", null)
  kms_key_version_id          = lookup(each.value, "kms_key_version_id", null)
  defined_tags                = lookup(each.value, "defined_tags", null)
  freeform_tags               = lookup(each.value, "freeform_tags", null)

  # ----------------------------
  # Database(s) under DB Home
  # ----------------------------
  dynamic "database" {
    for_each = each.value.database != null ? each.value.database : {}

    content {
      admin_password = sensitive(lookup(database.value, "admin_password", null))
      db_name        = lookup(database.value, "db_name", null)
      db_workload    = lookup(database.value, "db_workload", null)

      pdb_name            = lookup(database.value, "pdb_name", null)
      sid_prefix          = lookup(database.value, "sid_prefix", null)
      character_set       = lookup(database.value, "character_set", null)
      ncharacter_set      = lookup(database.value, "ncharacter_set", null)
      pluggable_databases = lookup(database.value, "pluggable_databases", null)

      backup_id                  = lookup(database.value, "backup_id", null)
      backup_tde_password        = lookup(database.value, "backup_tde_password", null)
      database_id                = lookup(database.value, "database_id", null)
      database_software_image_id = lookup(database.value, "database_software_image_id", null)

      # Backup Config
      dynamic "db_backup_config" {
        for_each = lookup(database, "db_backup_config", [])

        content {
          auto_backup_enabled       = lookup(db_backup_config.value, "auto_backup_enabled", null)
          auto_backup_window        = lookup(db_backup_config.value, "auto_backup_window", null)
          auto_full_backup_day      = lookup(db_backup_config.value, "auto_full_backup_day", null)
          auto_full_backup_window   = lookup(db_backup_config.value, "auto_full_backup_window", null)
          backup_deletion_policy    = lookup(db_backup_config.value, "backup_deletion_policy", null)
          recovery_window_in_days   = lookup(db_backup_config.value, "recovery_window_in_days", null)
          run_immediate_full_backup = lookup(db_backup_config.value, "run_immediate_full_backup", null)

          dynamic "backup_destination_details" {
            for_each = lookup(db_backup_config.value, "backup_destination_details", [])

            content {
              dbrs_policy_id = lookup(backup_destination_details.value, "dbrs_policy_id", null) == null ? null : (can(regex("^ocid1\\.", lookup(backup_destination_details.value, "dbrs_policy_id", null))) ? lookup(backup_destination_details.value, "dbrs_policy_id", null) : local.recovery_service_protection_policies[lookup(backup_destination_details.value, "dbrs_policy_id", null)].id)
              id             = lookup(backup_destination_details.value, "id", null)
              is_remote      = lookup(backup_destination_details.value, "is_remote", null)
              remote_region  = lookup(backup_destination_details.value, "remote_region", null)
              type           = lookup(backup_destination_details.value, "type", null)
            }
          }
        }
      }

      # Encryption / Security
      tde_wallet_password = sensitive(lookup(database.value, "tde_wallet_password", null))
      key_store_id        = lookup(database.value, "key_store_id", null)
      kms_key_id          = lookup(database.value, "kms_key_id", null)
      kms_key_version_id  = lookup(database.value, "kms_key_version_id", null)
      vault_id            = lookup(database.value, "vault_id", null)

      dynamic "encryption_key_location_details" {
        for_each = lookup(database, "encryption_key_location_details", [])

        content {
          provider_type           = lookup(encryption_key_location_details.value, "provider_type", null)
          azure_encryption_key_id = lookup(encryption_key_location_details.value, "azure_encryption_key_id", null)
          hsm_password            = lookup(encryption_key_location_details.value, "hsm_password", null)
        }
      }

      # PITR
      time_stamp_for_point_in_time_recovery = lookup(database.value, "time_stamp_for_point_in_time_recovery", null)

      # Tags
      defined_tags  = lookup(database.value, "defined_tags", null)
      freeform_tags = lookup(database.value, "freeform_tags", null)
    }
  }

  lifecycle {
    ignore_changes = [
      db_version,
      database_software_image_id
    ]
  }
}
