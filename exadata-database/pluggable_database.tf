# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  # Resolve references and defaults for pluggable database creation
  pluggable_databases = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) :
    key => merge(pdb, {
      # Resolve Container Database ID: use as-is if OCID, or reference created container DB by key
      source_pluggable_database_id_input = try(pdb.pdb_creation_type_details.source_pluggable_database_id, null)
      container_database_id              = can(regex("^ocid1\\.database\\.", pdb.container_database_id)) ? pdb.container_database_id : try(oci_database_database.these[pdb.container_database_id].id, var.exadata_database_dependency.databases[pdb.container_database_id].id, null)
      pdb_creation_type_details = try(pdb.pdb_creation_type_details, null) != null ? merge(pdb.pdb_creation_type_details, {
        source_pluggable_database_id = can(regex("^ocid1\\.", pdb.pdb_creation_type_details.source_pluggable_database_id)) ? pdb.pdb_creation_type_details.source_pluggable_database_id : try(var.exadata_database_dependency.pluggable_databases[pdb.pdb_creation_type_details.source_pluggable_database_id].id, null)
      }) : null
      # Tag defaults
      defined_tags  = coalesce(try(pdb.defined_tags, null), var.default_defined_tags)
      freeform_tags = coalesce(try(pdb.freeform_tags, null), var.default_freeform_tags)
    })
  }
}

resource "oci_database_pluggable_database" "these" {
  for_each = local.pluggable_databases
  #Required
  container_database_id = each.value.container_database_id
  pdb_name              = each.value.pdb_name
  #Optional
  container_database_admin_password = sensitive(each.value.container_database_admin_password)
  defined_tags                      = each.value.defined_tags
  freeform_tags                     = each.value.freeform_tags
  kms_key_version_id                = each.value.kms_key_version_id
  pdb_admin_password                = sensitive(each.value.pdb_admin_password)
  dynamic "pdb_creation_type_details" {
    for_each = each.value.pdb_creation_type_details != null ? [each.value.pdb_creation_type_details] : []
    content {
      creation_type                = pdb_creation_type_details.value.creation_type
      source_pluggable_database_id = pdb_creation_type_details.value.source_pluggable_database_id
      dblink_user_password         = sensitive(pdb_creation_type_details.value.dblink_user_password)
      dblink_username              = pdb_creation_type_details.value.dblink_username
      is_thin_clone                = pdb_creation_type_details.value.is_thin_clone
      dynamic "refreshable_clone_details" {
        for_each = try(pdb_creation_type_details.value.refreshable_clone_details, null) != null ? [pdb_creation_type_details.value.refreshable_clone_details] : []
        content {
          is_refreshable_clone = refreshable_clone_details.value.is_refreshable_clone
        }
      }
      source_container_database_admin_password = sensitive(pdb_creation_type_details.value.source_container_database_admin_password)
    }
  }
  should_create_pdb_backup           = each.value.should_create_pdb_backup
  should_pdb_admin_account_be_locked = each.value.should_pdb_admin_account_be_locked
  tde_wallet_password                = sensitive(each.value.tde_wallet_password)

  lifecycle {
    precondition {
      condition     = each.value.container_database_id != null && can(regex("^ocid1\\.database\\.", each.value.container_database_id))
      error_message = "container_database_id must be a database OCID or a key that resolves to a database dependency; DB Home OCIDs are not valid PDB container database IDs."
    }

    precondition {
      condition     = each.value.source_pluggable_database_id_input == null ? true : (try(each.value.pdb_creation_type_details.source_pluggable_database_id, null) != null && can(regex("^ocid1\\.pluggabledatabase\\.", each.value.pdb_creation_type_details.source_pluggable_database_id)))
      error_message = "source_pluggable_database_id must be a pluggable database OCID or a key in exadata_database_dependency.pluggable_databases."
    }

    ignore_changes = [
      # Ignore changes to the following attributes after creation
      container_database_admin_password,
      pdb_admin_password
    ]
  }

  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }
}
