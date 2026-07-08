# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
locals {
  cloud_db_homes_with_legacy_inline_database = toset([
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) :
    dbhome_key
    if try(length(coalesce(dbhome.database, {})) > 0 && dbhome.vm_cluster_id != null, false)
  ])

  cloud_db_homes = {
    for dbhome_key, dbhome in coalesce(var.cloud_db_homes_configuration, {}) :
    dbhome_key => merge(dbhome, {
      # Resolve VM Cluster ID: use as-is if OCID, or reference created VM cluster by key
      vm_cluster_id_input = dbhome.vm_cluster_id
      kms_key_id_input    = dbhome.kms_key_id
      vm_cluster_id       = can(regex("^ocid1\\.", dbhome.vm_cluster_id)) ? dbhome.vm_cluster_id : try(oci_database_cloud_vm_cluster.these[dbhome.vm_cluster_id].id, var.exadata_database_dependency.cloud_vm_clusters[dbhome.vm_cluster_id].id, null)
      kms_key_id          = can(regex("^ocid1\\.", dbhome.kms_key_id)) ? dbhome.kms_key_id : try(var.kms_dependency[dbhome.kms_key_id].id, null)
      source              = contains(local.cloud_db_homes_with_legacy_inline_database, dbhome_key) ? "VM_CLUSTER_NEW" : dbhome.source
      defined_tags        = coalesce(try(dbhome.defined_tags, null), var.default_defined_tags)
      freeform_tags       = coalesce(try(dbhome.freeform_tags, null), var.default_freeform_tags)
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
  kms_key_id                  = each.value.kms_key_id
  kms_key_version_id          = lookup(each.value, "kms_key_version_id", null)
  defined_tags                = each.value.defined_tags
  freeform_tags               = each.value.freeform_tags

  lifecycle {
    precondition {
      condition     = each.value.source != "VM_CLUSTER_NEW" ? true : (each.value.vm_cluster_id != null && can(regex("^ocid1\\.cloudvmcluster\\.", each.value.vm_cluster_id)))
      error_message = "vm_cluster_id must be a Cloud VM Cluster OCID or a key in exadata_database_dependency.cloud_vm_clusters."
    }

    precondition {
      condition     = each.value.kms_key_id_input == null ? true : (each.value.kms_key_id != null && can(regex("^ocid1\\.", each.value.kms_key_id)))
      error_message = "kms_key_id must be an OCID or a key in kms_dependency."
    }

    ignore_changes = [
      db_version,
      database_software_image_id
    ]
  }
}
