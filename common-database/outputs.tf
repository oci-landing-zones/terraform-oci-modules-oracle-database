# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "database_homes" {
  description = "The deployed Database Homes."
  value       = var.enable_output ? oci_database_db_home.these : null
  sensitive   = true
}

output "databases" {
  description = "The deployed standalone container databases."
  value       = var.enable_output ? oci_database_database.these : null
  sensitive   = true
}

output "pluggable_databases" {
  description = "The deployed pluggable databases."
  value       = var.enable_output ? oci_database_pluggable_database.these : null
  sensitive   = true
}

locals {
  legacy_inline_database_resources = {
    for key, entry in local.legacy_cloud_db_home_database_configs :
    key => {
      id = oci_database_db_home.these[entry.dbhome_key].database[0].id
    }
  }

  standalone_database_resources = {
    for key, database in oci_database_database.these :
    key => { id = database.id }
  }

  database_resources = {
    database_homes      = { for k, v in oci_database_db_home.these : k => { id = v.id, compartment_id = try(v.compartment_id, null) } }
    databases           = merge(local.legacy_inline_database_resources, local.standalone_database_resources)
    pluggable_databases = { for k, v in oci_database_pluggable_database.these : k => { id = v.id } }
  }
}

output "database_resources" {
  description = "Minimal database resource map for downstream dependency consumption."
  value       = var.enable_output ? local.database_resources : null
}

output "database_dependency" {
  description = "Alias of database_resources for direct downstream module consumption."
  value       = var.enable_output ? local.database_resources : null
}
