# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  cloud_db_homes = {
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) :
    dbhome_key => merge(dbhome, {
      # Resolve VM Cluster ID: use as-is if OCID, or reference created VM cluster by key
      vm_cluster_id_input = dbhome.vm_cluster_id
      kms_key_id_input    = dbhome.kms_key_id
      vm_cluster_id       = dbhome.vm_cluster_id == null ? null : (can(regex("^ocid1\\.", dbhome.vm_cluster_id)) ? dbhome.vm_cluster_id : try(var.vm_cluster_dependency[dbhome.vm_cluster_id].id, null))
      db_system_id_input  = dbhome.db_system_id
      db_system_id        = dbhome.db_system_id == null ? null : (can(regex("^ocid1\\.", dbhome.db_system_id)) ? dbhome.db_system_id : try(var.db_system_dependency[dbhome.db_system_id].id, null))
      kms_key_id          = can(regex("^ocid1\\.", dbhome.kms_key_id)) ? dbhome.kms_key_id : try(var.kms_dependency[dbhome.kms_key_id].id, null)
      source              = dbhome.source
      defined_tags        = coalesce(try(dbhome.defined_tags, null), var.default_defined_tags)
      freeform_tags       = coalesce(try(dbhome.freeform_tags, null), var.default_freeform_tags)
    })
  }
}

resource "oci_database_db_home" "these" {
  for_each = local.cloud_db_homes

  # ----------------------------
  # Required / core attributes
  # ----------------------------
  display_name  = each.value.display_name
  db_version    = each.value.db_version
  source        = each.value.source
  vm_cluster_id = lookup(each.value, "vm_cluster_id", null)
  db_system_id  = each.value.db_system_id

  # ----------------------------
  # Optional metadata / config
  # ----------------------------
  database_software_image_id  = lookup(each.value, "database_software_image_id", null)
  enable_database_delete      = lookup(each.value, "enable_database_delete", null)
  is_desupported_version      = lookup(each.value, "is_desupported_version", null)
  is_unified_auditing_enabled = lookup(each.value, "is_unified_auditing_enabled", null)
  kms_key_id                  = each.value.kms_key_id
  kms_key_version_id          = lookup(each.value, "kms_key_version_id", null)
  defined_tags                = each.value.defined_tags
  freeform_tags               = each.value.freeform_tags

  # Deprecated v1.1.0 compatibility path. Existing inline CDBs remain owned by
  # their DB Home throughout the 1.2.x release line; new CDBs use
  # databases_configuration and oci_database_database.
  dynamic "database" {
    for_each = each.value.database != null ? each.value.database : {}

    content {
      admin_password = sensitive(lookup(database.value, "admin_password", null))
      db_name        = lookup(database.value, "db_name", null)
      db_workload    = lookup(database.value, "db_workload", null)

      pdb_name            = lookup(database.value, "pdb_name", null)
      character_set       = lookup(database.value, "character_set", null)
      ncharacter_set      = lookup(database.value, "ncharacter_set", null)
      pluggable_databases = lookup(database.value, "pluggable_databases", null)

      backup_id                  = lookup(database.value, "backup_id", null)
      backup_tde_password        = sensitive(lookup(database.value, "backup_tde_password", null))
      database_id                = lookup(database.value, "database_id", null)
      database_software_image_id = lookup(database.value, "database_software_image_id", null)

      dynamic "db_backup_config" {
        for_each = lookup(database.value, "db_backup_config", null) != null ? database.value.db_backup_config : {}

        content {
          auto_backup_enabled       = lookup(db_backup_config.value, "auto_backup_enabled", null)
          auto_backup_window        = lookup(db_backup_config.value, "auto_backup_window", null)
          auto_full_backup_day      = lookup(db_backup_config.value, "auto_full_backup_day", null)
          auto_full_backup_window   = lookup(db_backup_config.value, "auto_full_backup_window", null)
          backup_deletion_policy    = lookup(db_backup_config.value, "backup_deletion_policy", null)
          recovery_window_in_days   = lookup(db_backup_config.value, "recovery_window_in_days", null)
          run_immediate_full_backup = lookup(db_backup_config.value, "run_immediate_full_backup", null)

          dynamic "backup_destination_details" {
            for_each = lookup(db_backup_config.value, "backup_destination_details", null) != null ? db_backup_config.value.backup_destination_details : {}

            content {
              dbrs_policy_id = lookup(backup_destination_details.value, "dbrs_policy_id", null)
              id             = lookup(backup_destination_details.value, "id", null)
              is_remote      = lookup(backup_destination_details.value, "is_remote", null)
              remote_region  = lookup(backup_destination_details.value, "remote_region", null)
              type           = lookup(backup_destination_details.value, "type", null)
            }
          }
        }
      }

      tde_wallet_password = sensitive(lookup(database.value, "tde_wallet_password", null))
      key_store_id        = lookup(database.value, "key_store_id", null)
      kms_key_id          = lookup(database.value, "kms_key_id", null)
      kms_key_version_id  = lookup(database.value, "kms_key_version_id", null)
      vault_id            = lookup(database.value, "vault_id", null)
      defined_tags        = lookup(database.value, "defined_tags", null)
      freeform_tags       = lookup(database.value, "freeform_tags", null)

      dynamic "encryption_key_location_details" {
        for_each = lookup(database.value, "encryption_key_location_details", null) != null ? database.value.encryption_key_location_details : {}

        content {
          provider_type           = lookup(encryption_key_location_details.value, "provider_type", null)
          azure_encryption_key_id = lookup(encryption_key_location_details.value, "azure_encryption_key_id", null)
          hsm_password            = sensitive(lookup(encryption_key_location_details.value, "hsm_password", null))
        }
      }

      time_stamp_for_point_in_time_recovery = lookup(database.value, "time_stamp_for_point_in_time_recovery", null)
    }
  }

  lifecycle {
    precondition {
      condition     = !(each.value.vm_cluster_id != null && each.value.db_system_id != null)
      error_message = "Only one of vm_cluster_id or db_system_id can be set for a DB Home."
    }

    precondition {
      condition     = each.value.source != "VM_CLUSTER_NEW" ? true : (each.value.vm_cluster_id != null && can(regex("^ocid1\\.cloudvmcluster\\.", each.value.vm_cluster_id)))
      error_message = "vm_cluster_id must be a Cloud VM Cluster OCID or a key in vm_cluster_dependency."
    }

    precondition {
      condition     = each.value.db_system_id_input == null ? true : (each.value.db_system_id != null && can(regex("^ocid1\\.dbsystem\\.", each.value.db_system_id)))
      error_message = "db_system_id must be a DB System OCID or a key in db_system_dependency."
    }

    precondition {
      condition     = each.value.kms_key_id_input == null ? true : (each.value.kms_key_id != null && can(regex("^ocid1\\.", each.value.kms_key_id)))
      error_message = "kms_key_id must be an OCID or a key in kms_dependency."
    }

    ignore_changes = [
      db_version,
      database_software_image_id,
      database.0.admin_password,
      database.0.backup_tde_password,
      database.0.tde_wallet_password,
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
      database.0.defined_tags["Oracle-Tags.CreatedBy"],
      database.0.defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}
