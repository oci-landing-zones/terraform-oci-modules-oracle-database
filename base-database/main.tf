# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_recovery_protection_policies" "oracle_managed" {
  for_each       = var.recovery_service_dependency == null ? local.oracle_recovery_policy_keys : toset([])
  compartment_id = var.tenancy_ocid
  display_name   = title(each.key)
}

data "oci_secrets_secretbundle" "admin_password" {
  for_each  = local.secret_ids
  secret_id = each.value
  stage     = "CURRENT"

  lifecycle {
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current admin password secret content must be nonempty valid Base64."
    }
  }
}

data "oci_secrets_secretbundle" "additional_pdb_admin_password" {
  for_each  = local.additional_pdb_secret_ids
  secret_id = each.value
  stage     = "CURRENT"

  lifecycle {
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current additional PDB admin password secret content must be nonempty valid Base64."
    }
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "oci_database_db_system" "these" {
  for_each = toset(keys(local.db_systems))

  lifecycle {
    precondition {
      condition     = local.db_system_compartment_ids[each.key] != null
      error_message = "${each.key} compartment_id must be an OCID or a key in compartments_dependency."
    }

    precondition {
      condition     = local.db_system_subnet_ids[each.key] != null
      error_message = "${each.key} subnet_id must be an OCID or a key in network_dependency.subnets."
    }

    precondition {
      condition     = alltrue([for id in local.db_system_nsg_ids[each.key] : id != null])
      error_message = "${each.key} nsg_ids must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }

    precondition {
      condition     = local.db_systems[each.key].kms_key_id == null || local.db_system_kms_key_ids[each.key] != null
      error_message = "${each.key} kms_key_id must be an OCID or a key in kms_dependency."
    }

    precondition {
      condition     = local.db_systems[each.key].kms_key_version_id == null || can(regex("^ocid1\\.keyversion\\.", local.db_systems[each.key].kms_key_version_id))
      error_message = "${each.key} kms_key_version_id must be a key-version OCID."
    }

    precondition {
      condition     = try(length(local.db_systems[each.key].db_home.database.admin_password) > 0, false) || try(local.secret_ids[each.key], null) != null
      error_message = "${each.key} admin_password_secret_id must be a secret OCID or a key in secrets_dependency."
    }

    precondition {
      condition = try(
        length(nonsensitive(local.db_system_container_passwords[each.key])) >= 9 &&
        length(nonsensitive(local.db_system_container_passwords[each.key])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.db_system_container_passwords[each.key]))) &&
        length(regexall("[A-Z]", nonsensitive(local.db_system_container_passwords[each.key]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.db_system_container_passwords[each.key]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.db_system_container_passwords[each.key]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.db_system_container_passwords[each.key]))) >= 2,
        false
      )
      error_message = "${each.key} resolved admin password must be 9-30 characters and contain at least two uppercase letters, lowercase letters, numbers, and special characters (#, _, -)."
    }

    precondition {
      condition     = length(coalesce(local.db_systems[each.key].hostname, lower(replace(local.db_systems[each.key].display_name, " ", "")))) <= 16
      error_message = "${each.key} hostname must be 16 characters or fewer."
    }

    precondition {
      condition     = try(local.db_systems[each.key].placement, null) == null || length(local.db_systems[each.key].placement.fault_domains) == 1
      error_message = "${each.key} must specify exactly one fault domain for node_count = 1."
    }

    precondition {
      condition     = local.db_systems[each.key].cpu_core_count > 0
      error_message = "${each.key} must use a cpu_core_count greater than zero."
    }

    precondition {
      condition     = try(local.db_systems[each.key].db_home.database.db_backup_config.backup_destination_details.type, null) != "DBRS" || try(local.db_system_dbrs_policy_ids[each.key], null) != null
      error_message = "${each.key} DBRS backup destination must resolve dbrs_policy_id to a recovery-policy OCID, a recovery_service_dependency key, or bronze, silver, gold, or platinum with tenancy_ocid set."
    }

    ignore_changes = [
      db_home[0].db_version,
      db_home[0].database[0].admin_password,
      db_home[0].database[0].backup_tde_password,
      db_home[0].database[0].tde_wallet_password,
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"]
    ]

  }

  availability_domain             = data.oci_identity_availability_domains.ads.availability_domains[(local.db_systems[each.key].placement != null ? local.db_systems[each.key].placement.availability_domain : 1) - 1].name
  compartment_id                  = local.db_system_compartment_ids[each.key]
  cpu_core_count                  = local.db_systems[each.key].cpu_core_count
  data_storage_size_in_gb         = local.db_systems[each.key].data_storage_size_in_gb
  database_edition                = local.db_systems[each.key].database_edition
  defined_tags                    = coalesce(try(local.db_systems[each.key].defined_tags, null), try(var.db_systems_configuration.default_defined_tags, null), {})
  display_name                    = local.db_systems[each.key].display_name
  fault_domains                   = [for fault_domain in(local.db_systems[each.key].placement != null ? local.db_systems[each.key].placement.fault_domains : [1]) : format("FAULT-DOMAIN-%s", fault_domain)]
  freeform_tags                   = merge(local.cislz_module_tag, coalesce(try(local.db_systems[each.key].freeform_tags, null), try(var.db_systems_configuration.default_freeform_tags, null), {}))
  hostname                        = coalesce(local.db_systems[each.key].hostname, lower(replace(local.db_systems[each.key].display_name, " ", "")))
  kms_key_id                      = local.db_system_kms_key_ids[each.key]
  kms_key_version_id              = local.db_system_kms_key_version_ids[each.key]
  license_model                   = local.db_systems[each.key].license_model
  node_count                      = 1
  nsg_ids                         = local.db_system_nsg_ids[each.key]
  shape                           = local.db_systems[each.key].shape
  ssh_public_keys                 = [for key in local.db_systems[each.key].ssh_public_keys : trimspace(key)]
  storage_volume_performance_mode = local.db_systems[each.key].storage_volume_performance_mode
  subnet_id                       = local.db_system_subnet_ids[each.key]
  time_zone                       = local.db_systems[each.key].time_zone

  db_system_options {
    storage_management = local.db_systems[each.key].db_system_options.storage_management
  }

  db_home {
    database_software_image_id  = local.db_systems[each.key].db_home.database_software_image_id
    db_version                  = local.db_systems[each.key].db_home.database.db_version
    display_name                = coalesce(local.db_systems[each.key].db_home.display_name, "${local.db_systems[each.key].display_name}-db-home")
    is_unified_auditing_enabled = local.db_systems[each.key].db_home.is_unified_auditing_enabled

    database {
      admin_password                        = local.db_system_container_passwords[each.key]
      backup_id                             = local.db_systems[each.key].db_home.database.backup_id
      backup_tde_password                   = sensitive(local.db_systems[each.key].db_home.database.backup_tde_password)
      character_set                         = local.db_systems[each.key].db_home.database.character_set
      database_software_image_id            = local.db_systems[each.key].db_home.database.database_software_image_id
      db_name                               = local.db_systems[each.key].db_home.database.db_name
      db_workload                           = local.db_systems[each.key].db_home.database.db_workload
      ncharacter_set                        = local.db_systems[each.key].db_home.database.ncharacter_set
      pdb_name                              = local.db_systems[each.key].db_home.database.pdb_name
      tde_wallet_password                   = sensitive(local.db_systems[each.key].db_home.database.tde_wallet_password)
      time_stamp_for_point_in_time_recovery = local.db_systems[each.key].db_home.database.time_stamp_for_point_in_time_recovery

      db_backup_config {
        auto_backup_enabled       = try(local.db_systems[each.key].db_home.database.db_backup_config.auto_backup_enabled, false)
        auto_backup_window        = try(local.db_systems[each.key].db_home.database.db_backup_config.auto_backup_window, null)
        auto_full_backup_day      = try(local.db_systems[each.key].db_home.database.db_backup_config.auto_full_backup_day, null)
        auto_full_backup_window   = try(local.db_systems[each.key].db_home.database.db_backup_config.auto_full_backup_window, null)
        backup_deletion_policy    = try(local.db_systems[each.key].db_home.database.db_backup_config.backup_deletion_policy, null)
        recovery_window_in_days   = try(local.db_systems[each.key].db_home.database.db_backup_config.auto_backup_enabled, false) ? try(local.db_systems[each.key].db_home.database.db_backup_config.recovery_window_in_days, 30) : null
        run_immediate_full_backup = try(local.db_systems[each.key].db_home.database.db_backup_config.run_immediate_full_backup, null)

        dynamic "backup_destination_details" {
          for_each = try(local.db_systems[each.key].db_home.database.db_backup_config.backup_destination_details, null) == null ? [] : [local.db_systems[each.key].db_home.database.db_backup_config.backup_destination_details]
          content {
            backup_retention_policy_on_terminate = try(backup_destination_details.value.backup_retention_policy_on_terminate, null)
            dbrs_policy_id                       = backup_destination_details.value.type == "DBRS" ? local.db_system_dbrs_policy_ids[each.key] : null
            id                                   = try(backup_destination_details.value.id, null)
            is_remote                            = try(backup_destination_details.value.is_remote, null)
            is_retention_lock_enabled            = try(backup_destination_details.value.is_retention_lock_enabled, null)
            remote_region                        = try(backup_destination_details.value.remote_region, null)
            type                                 = backup_destination_details.value.type
          }
        }
      }
    }
  }

}

resource "oci_database_pluggable_database" "these" {
  for_each = local.additional_pdbs

  lifecycle {
    ignore_changes = [
      container_database_admin_password,
      pdb_admin_password,
      tde_wallet_password,
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"]
    ]

    precondition {
      condition     = oci_database_db_system.these[each.value.db_system_key].db_home[0].database[0].id != null
      error_message = "${each.key} cannot be created because the parent container database ID is not available."
    }

    precondition {
      condition     = local.additional_pdb_admin_passwords[each.key] != null
      error_message = "${each.key} requires a resolved PDB admin password or pdb_admin_password_secret_id."
    }

    precondition {
      condition     = local.db_system_container_passwords[each.value.db_system_key] != null
      error_message = "${each.key} requires the resolved parent CDB password for the TDE wallet password."
    }

    precondition {
      condition     = length(each.value.pdb_name) <= 30 && can(regex("^[A-Za-z][A-Za-z0-9]*$", each.value.pdb_name))
      error_message = "${each.key} PDB name must start with a letter, contain only alphanumeric characters, and be at most 30 characters."
    }
  }

  container_database_id             = oci_database_db_system.these[each.value.db_system_key].db_home[0].database[0].id
  container_database_admin_password = sensitive(local.db_system_container_passwords[each.value.db_system_key])
  pdb_name                          = each.value.pdb_name
  pdb_admin_password                = sensitive(local.additional_pdb_admin_passwords[each.key])
  tde_wallet_password               = sensitive(local.db_system_container_passwords[each.value.db_system_key])
  defined_tags                      = each.value.defined_tags
  freeform_tags                     = each.value.freeform_tags
}
