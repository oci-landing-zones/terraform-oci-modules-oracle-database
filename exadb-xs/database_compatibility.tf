# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  db_homes_input = try(coalesce(var.cloud_db_homes_configuration, {}), {})
}

# Smart Storage supports 26ai databases only. The DB Home's db_version is the
# only locally inspectable version input; a database software image OCID needs
# an authenticated OCI lookup and is tracked separately in the test backlog.
resource "terraform_data" "smart_storage_database_compatibility" {
  for_each = local.vm_clusters

  lifecycle {
    precondition {
      condition = coalesce(each.value.shape_attribute, "SMART_STORAGE") != "SMART_STORAGE" ? true : alltrue([
        for db_home in values(local.db_homes_input) :
        try(db_home.vm_cluster_id, null) != each.key ||
        try(db_home.db_version, null) == null ||
        can(regex("^26", db_home.db_version))
      ])
      error_message = "cloud_db_homes_configuration entries referencing a SMART_STORAGE ExaDB-XS VM Cluster by local key must use db_version 26ai. A database_software_image_id without db_version requires authenticated OCI compatibility verification."
    }
  }
}
