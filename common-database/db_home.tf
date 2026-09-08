# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  legacy_admin_password_secret_id_inputs = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => try(trimspace(database.admin_password_secret_id), "")
    }
  ]...)

  legacy_backup_tde_password_secret_id_inputs = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => try(trimspace(database.backup_tde_password_secret_id), "")
    }
  ]...)

  legacy_encryption_hsm_password_secret_id_inputs = merge({}, flatten([
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : [
      for database_key, database in coalesce(dbhome.database, {}) : {
        for detail_key, detail in coalesce(database.encryption_key_location_details, {}) :
        jsonencode([dbhome_key, database_key, detail_key]) => try(trimspace(detail.hsm_password_secret_id), "")
      }
    ]
  ])...)

  legacy_tde_wallet_password_secret_id_inputs = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => try(trimspace(database.tde_wallet_password_secret_id), "")
    }
  ]...)

  legacy_admin_password_secret_ids = {
    for key, secret_ref in local.legacy_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (
      can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null)
    )
  }

  legacy_backup_tde_password_secret_ids = {
    for key, secret_ref in local.legacy_backup_tde_password_secret_id_inputs : key => secret_ref == "" ? null : (
      can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null)
    )
  }

  legacy_encryption_hsm_password_secret_ids = {
    for key, secret_ref in local.legacy_encryption_hsm_password_secret_id_inputs : key => secret_ref == "" ? null : (
      can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null)
    )
  }

  legacy_tde_wallet_password_secret_ids = {
    for key, secret_ref in local.legacy_tde_wallet_password_secret_id_inputs : key => secret_ref == "" ? null : (
      can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null)
    )
  }

  legacy_admin_passwords = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => sensitive(
        try(length(database.admin_password) > 0, false)
        ? database.admin_password
        : try(base64decode(data.oci_secrets_secretbundle.legacy_admin_password[jsonencode([dbhome_key, database_key])].secret_bundle_content[0].content), null)
      )
    }
  ]...)

  legacy_backup_tde_passwords = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => sensitive(
        try(length(database.backup_tde_password) > 0, false)
        ? database.backup_tde_password
        : try(base64decode(data.oci_secrets_secretbundle.legacy_backup_tde_password[jsonencode([dbhome_key, database_key])].secret_bundle_content[0].content), null)
      )
    }
  ]...)

  legacy_encryption_hsm_passwords = merge({}, flatten([
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : [
      for database_key, database in coalesce(dbhome.database, {}) : {
        for detail_key, detail in coalesce(database.encryption_key_location_details, {}) :
        jsonencode([dbhome_key, database_key, detail_key]) => sensitive(
          try(length(detail.hsm_password) > 0, false)
          ? detail.hsm_password
          : try(base64decode(data.oci_secrets_secretbundle.legacy_encryption_hsm_password[jsonencode([dbhome_key, database_key, detail_key])].secret_bundle_content[0].content), null)
        )
      }
    ]
  ])...)

  legacy_tde_wallet_passwords = merge({}, [
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) : {
      for database_key, database in coalesce(dbhome.database, {}) :
      jsonencode([dbhome_key, database_key]) => sensitive(
        try(length(database.tde_wallet_password) > 0, false)
        ? database.tde_wallet_password
        : try(base64decode(data.oci_secrets_secretbundle.legacy_tde_wallet_password[jsonencode([dbhome_key, database_key])].secret_bundle_content[0].content), null)
      )
    }
  ]...)

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

data "oci_secrets_secretbundle" "legacy_admin_password" {
  for_each = { for key, secret_ref in local.legacy_admin_password_secret_id_inputs : key => local.legacy_admin_password_secret_ids[key] if secret_ref != "" }

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

data "oci_secrets_secretbundle" "legacy_backup_tde_password" {
  for_each = { for key, secret_ref in local.legacy_backup_tde_password_secret_id_inputs : key => local.legacy_backup_tde_password_secret_ids[key] if secret_ref != "" }

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

data "oci_secrets_secretbundle" "legacy_encryption_hsm_password" {
  for_each = { for key, secret_ref in local.legacy_encryption_hsm_password_secret_id_inputs : key => local.legacy_encryption_hsm_password_secret_ids[key] if secret_ref != "" }

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

data "oci_secrets_secretbundle" "legacy_tde_wallet_password" {
  for_each = { for key, secret_ref in local.legacy_tde_wallet_password_secret_id_inputs : key => local.legacy_tde_wallet_password_secret_ids[key] if secret_ref != "" }

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
  freeform_tags               = merge(local.cislz_module_tag, each.value.freeform_tags)

  # Deprecated v1.1.0 compatibility path. Existing inline CDBs remain owned by
  # their DB Home throughout the 1.2.x release line; new CDBs use
  # databases_configuration and oci_database_database.
  dynamic "database" {
    for_each = each.value.database != null ? each.value.database : {}

    content {
      admin_password = local.legacy_admin_passwords[jsonencode([each.key, database.key])]
      db_name        = lookup(database.value, "db_name", null)
      db_workload    = lookup(database.value, "db_workload", null)

      pdb_name            = lookup(database.value, "pdb_name", null)
      character_set       = lookup(database.value, "character_set", null)
      ncharacter_set      = lookup(database.value, "ncharacter_set", null)
      pluggable_databases = lookup(database.value, "pluggable_databases", null)

      backup_id                  = lookup(database.value, "backup_id", null)
      backup_tde_password        = local.legacy_backup_tde_passwords[jsonencode([each.key, database.key])]
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

      tde_wallet_password = local.legacy_tde_wallet_passwords[jsonencode([each.key, database.key])]
      key_store_id        = lookup(database.value, "key_store_id", null)
      kms_key_id          = lookup(database.value, "kms_key_id", null)
      kms_key_version_id  = lookup(database.value, "kms_key_version_id", null)
      vault_id            = lookup(database.value, "vault_id", null)
      defined_tags        = lookup(database.value, "defined_tags", null)
      freeform_tags       = merge(local.cislz_module_tag, coalesce(lookup(database.value, "freeform_tags", null), {}))

      dynamic "encryption_key_location_details" {
        for_each = lookup(database.value, "encryption_key_location_details", null) != null ? database.value.encryption_key_location_details : {}

        content {
          provider_type           = lookup(encryption_key_location_details.value, "provider_type", null)
          azure_encryption_key_id = lookup(encryption_key_location_details.value, "azure_encryption_key_id", null)
          hsm_password            = local.legacy_encryption_hsm_passwords[jsonencode([each.key, database.key, encryption_key_location_details.key])]
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

    precondition {
      condition = alltrue([for database_key, database in coalesce(each.value.database, {}) : try(
        length(nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])])) >= 9 &&
        length(nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])]))) &&
        length(regexall("[A-Z]", nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.legacy_admin_passwords[jsonencode([each.key, database_key])]))) >= 2,
        false
      )])
      error_message = "The resolved legacy admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    precondition {
      condition = alltrue([for database_key, database in coalesce(each.value.database, {}) : try(
        !try(length(database.tde_wallet_password) > 0, false) && local.legacy_tde_wallet_password_secret_id_inputs[jsonencode([each.key, database_key])] == "" ? true : (
          length(nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])])) >= 9 &&
          length(nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])])) <= 30 &&
          can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])]))) &&
          length(regexall("[A-Z]", nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
          length(regexall("[a-z]", nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
          length(regexall("[0-9]", nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])]))) >= 2 &&
          length(regexall("[#_-]", nonsensitive(local.legacy_tde_wallet_passwords[jsonencode([each.key, database_key])]))) >= 2
        ),
        false
      )])
      error_message = "The resolved legacy TDE wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
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
