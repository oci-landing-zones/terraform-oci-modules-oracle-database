# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  pdb_container_admin_password_secret_id_inputs = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => try(trimspace(pdb.container_database_admin_password_secret_id), "")
  }
  pdb_admin_password_secret_id_inputs = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => try(trimspace(pdb.pdb_admin_password_secret_id), "")
  }
  pdb_dblink_user_password_secret_id_inputs = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => try(trimspace(pdb.pdb_creation_type_details.dblink_user_password_secret_id), "")
  }
  pdb_source_container_admin_password_secret_id_inputs = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => try(trimspace(pdb.pdb_creation_type_details.source_container_database_admin_password_secret_id), "")
  }
  pdb_tde_wallet_password_secret_id_inputs = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => try(trimspace(pdb.tde_wallet_password_secret_id), "")
  }

  pdb_container_admin_password_secret_ids = {
    for key, secret_ref in local.pdb_container_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  pdb_admin_password_secret_ids = {
    for key, secret_ref in local.pdb_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  pdb_dblink_user_password_secret_ids = {
    for key, secret_ref in local.pdb_dblink_user_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  pdb_source_container_admin_password_secret_ids = {
    for key, secret_ref in local.pdb_source_container_admin_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }
  pdb_tde_wallet_password_secret_ids = {
    for key, secret_ref in local.pdb_tde_wallet_password_secret_id_inputs : key => secret_ref == "" ? null : (can(regex("^ocid1\\.vaultsecret\\.", secret_ref)) ? secret_ref : try(trimspace(var.secrets_dependency[secret_ref].id), null))
  }

  pdb_admin_passwords = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => sensitive(try(length(pdb.pdb_admin_password) > 0, false) ? pdb.pdb_admin_password : try(base64decode(data.oci_secrets_secretbundle.pdb_admin_password[key].secret_bundle_content[0].content), null))
  }
  pdb_tde_wallet_passwords = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) : key => sensitive(try(length(pdb.tde_wallet_password) > 0, false) ? pdb.tde_wallet_password : try(base64decode(data.oci_secrets_secretbundle.pdb_tde_wallet_password[key].secret_bundle_content[0].content), null))
  }

  # Resolve references and defaults for pluggable database creation
  pluggable_databases = {
    for key, pdb in coalesce(var.pluggable_databases_configuration, {}) :
    key => merge(pdb, {
      # Resolve Container Database ID: use as-is if OCID, or reference created container DB by key
      source_pluggable_database_id_input = try(pdb.pdb_creation_type_details.source_pluggable_database_id, null)
      container_database_id              = can(regex("^ocid1\\.database\\.", pdb.container_database_id)) ? pdb.container_database_id : try(oci_database_database.these[pdb.container_database_id].id, local.legacy_inline_database_resources[pdb.container_database_id].id, var.database_dependency.databases[pdb.container_database_id].id, null)
      pdb_creation_type_details = try(pdb.pdb_creation_type_details, null) != null ? merge(pdb.pdb_creation_type_details, {
        source_pluggable_database_id = can(regex("^ocid1\\.", pdb.pdb_creation_type_details.source_pluggable_database_id)) ? pdb.pdb_creation_type_details.source_pluggable_database_id : try(var.database_dependency.pluggable_databases[pdb.pdb_creation_type_details.source_pluggable_database_id].id, null)
      }) : null
      # Tag defaults
      defined_tags  = coalesce(try(pdb.defined_tags, null), var.default_defined_tags)
      freeform_tags = coalesce(try(pdb.freeform_tags, null), var.default_freeform_tags)
    })
  }
}

data "oci_secrets_secretbundle" "pdb_container_admin_password" {
  for_each  = { for key, ref in local.pdb_container_admin_password_secret_id_inputs : key => local.pdb_container_admin_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "container_database_admin_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current container database admin password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "pdb_admin_password" {
  for_each  = { for key, ref in local.pdb_admin_password_secret_id_inputs : key => local.pdb_admin_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "pdb_admin_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current PDB admin password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "pdb_dblink_user_password" {
  for_each  = { for key, ref in local.pdb_dblink_user_password_secret_id_inputs : key => local.pdb_dblink_user_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "dblink_user_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current database-link password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "pdb_source_container_admin_password" {
  for_each  = { for key, ref in local.pdb_source_container_admin_password_secret_id_inputs : key => local.pdb_source_container_admin_password_secret_ids[key] if ref != "" }
  secret_id = each.value
  stage     = "CURRENT"
  lifecycle {
    precondition {
      condition     = each.value != null && can(regex("^ocid1\\.vaultsecret\\.", each.value))
      error_message = "source_container_database_admin_password_secret_id must be an OCI Vault secret OCID or a key in secrets_dependency."
    }
    postcondition {
      condition     = try(length(base64decode(self.secret_bundle_content[0].content)) > 0, false)
      error_message = "The current source container admin password secret content must be nonempty valid Base64."
    }
  }
}
data "oci_secrets_secretbundle" "pdb_tde_wallet_password" {
  for_each  = { for key, ref in local.pdb_tde_wallet_password_secret_id_inputs : key => local.pdb_tde_wallet_password_secret_ids[key] if ref != "" }
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

resource "oci_database_pluggable_database" "these" {
  # Match the ARS pattern: establish resource identity from the original
  # configuration and resolve sensitive passwords in resource attributes.
  for_each = coalesce(var.pluggable_databases_configuration, {})
  #Required
  container_database_id = local.pluggable_databases[each.key].container_database_id
  pdb_name              = local.pluggable_databases[each.key].pdb_name
  #Optional
  container_database_admin_password = sensitive(
    try(length(each.value.container_database_admin_password) > 0, false)
    ? each.value.container_database_admin_password
    : try(base64decode(data.oci_secrets_secretbundle.pdb_container_admin_password[each.key].secret_bundle_content[0].content), null)
  )
  defined_tags       = local.pluggable_databases[each.key].defined_tags
  freeform_tags      = local.pluggable_databases[each.key].freeform_tags
  kms_key_version_id = local.pluggable_databases[each.key].kms_key_version_id
  pdb_admin_password = sensitive(
    try(length(each.value.pdb_admin_password) > 0, false)
    ? each.value.pdb_admin_password
    : try(base64decode(data.oci_secrets_secretbundle.pdb_admin_password[each.key].secret_bundle_content[0].content), null)
  )
  dynamic "pdb_creation_type_details" {
    for_each = local.pluggable_databases[each.key].pdb_creation_type_details != null ? [local.pluggable_databases[each.key].pdb_creation_type_details] : []
    content {
      creation_type                = pdb_creation_type_details.value.creation_type
      source_pluggable_database_id = pdb_creation_type_details.value.source_pluggable_database_id
      dblink_user_password = sensitive(
        try(length(each.value.pdb_creation_type_details.dblink_user_password) > 0, false)
        ? each.value.pdb_creation_type_details.dblink_user_password
        : try(base64decode(data.oci_secrets_secretbundle.pdb_dblink_user_password[each.key].secret_bundle_content[0].content), null)
      )
      dblink_username = pdb_creation_type_details.value.dblink_username
      is_thin_clone   = pdb_creation_type_details.value.is_thin_clone
      dynamic "refreshable_clone_details" {
        for_each = try(pdb_creation_type_details.value.refreshable_clone_details, null) != null ? [pdb_creation_type_details.value.refreshable_clone_details] : []
        content {
          is_refreshable_clone = refreshable_clone_details.value.is_refreshable_clone
        }
      }
      source_container_database_admin_password = sensitive(
        try(length(each.value.pdb_creation_type_details.source_container_database_admin_password) > 0, false)
        ? each.value.pdb_creation_type_details.source_container_database_admin_password
        : try(base64decode(data.oci_secrets_secretbundle.pdb_source_container_admin_password[each.key].secret_bundle_content[0].content), null)
      )
    }
  }
  should_create_pdb_backup           = local.pluggable_databases[each.key].should_create_pdb_backup
  should_pdb_admin_account_be_locked = local.pluggable_databases[each.key].should_pdb_admin_account_be_locked
  tde_wallet_password = sensitive(
    try(length(each.value.tde_wallet_password) > 0, false)
    ? each.value.tde_wallet_password
    : try(base64decode(data.oci_secrets_secretbundle.pdb_tde_wallet_password[each.key].secret_bundle_content[0].content), null)
  )

  lifecycle {
    precondition {
      condition     = local.pluggable_databases[each.key].container_database_id != null && can(regex("^ocid1\\.database\\.", local.pluggable_databases[each.key].container_database_id))
      error_message = "container_database_id must be a database OCID or a key that resolves to a database dependency; DB Home OCIDs are not valid PDB container database IDs."
    }

    precondition {
      condition     = local.pluggable_databases[each.key].source_pluggable_database_id_input == null ? true : (try(local.pluggable_databases[each.key].pdb_creation_type_details.source_pluggable_database_id, null) != null && can(regex("^ocid1\\.pluggabledatabase\\.", local.pluggable_databases[each.key].pdb_creation_type_details.source_pluggable_database_id)))
      error_message = "source_pluggable_database_id must be a pluggable database OCID or a key in database_dependency.pluggable_databases."
    }

    precondition {
      condition = !try(length(var.pluggable_databases_configuration[each.key].pdb_admin_password) > 0, false) && local.pdb_admin_password_secret_id_inputs[each.key] == "" ? true : try(
        length(nonsensitive(local.pdb_admin_passwords[each.key])) >= 9 &&
        length(nonsensitive(local.pdb_admin_passwords[each.key])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.pdb_admin_passwords[each.key]))) &&
        length(regexall("[A-Z]", nonsensitive(local.pdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.pdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.pdb_admin_passwords[each.key]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.pdb_admin_passwords[each.key]))) >= 2,
        false
      )
      error_message = "The resolved PDB admin password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    precondition {
      condition = !try(length(var.pluggable_databases_configuration[each.key].tde_wallet_password) > 0, false) && local.pdb_tde_wallet_password_secret_id_inputs[each.key] == "" ? true : try(
        length(nonsensitive(local.pdb_tde_wallet_passwords[each.key])) >= 9 &&
        length(nonsensitive(local.pdb_tde_wallet_passwords[each.key])) <= 30 &&
        can(regex("^[A-Za-z0-9#_-]+$", nonsensitive(local.pdb_tde_wallet_passwords[each.key]))) &&
        length(regexall("[A-Z]", nonsensitive(local.pdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[a-z]", nonsensitive(local.pdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[0-9]", nonsensitive(local.pdb_tde_wallet_passwords[each.key]))) >= 2 &&
        length(regexall("[#_-]", nonsensitive(local.pdb_tde_wallet_passwords[each.key]))) >= 2,
        false
      )
      error_message = "The resolved PDB TDE wallet password needs to contain 2 uppercase, 2 lowercase, 2 numbers, 2 special characters (#, _, -), and length of 9 to 30 characters."
    }

    ignore_changes = [
      # Ignore changes to the following attributes after creation
      container_database_admin_password,
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
      pdb_admin_password,
      tde_wallet_password
    ]
  }

  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }
}
