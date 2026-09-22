# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "exascale_db_storage_vaults" {
  description = "The deployed Exascale DB Storage Vaults, managed by the reusable child module."
  value       = var.enable_output ? module.exascale_db_storage_vault.exascale_db_storage_vaults : null
}

output "exadb_vm_clusters" {
  description = "The deployed ExaDB-XS VM Clusters."
  value       = var.enable_output ? oci_database_exadb_vm_cluster.these : null
}

output "database_homes" {
  description = "The deployed Database Homes."
  value       = var.enable_output ? module.common_database.database_homes : null
  sensitive   = true
}

output "databases" {
  description = "The deployed container databases."
  value       = var.enable_output ? module.common_database.databases : null
  sensitive   = true
}

output "pluggable_databases" {
  description = "The deployed pluggable databases."
  value       = var.enable_output ? module.common_database.pluggable_databases : null
  sensitive   = true
}

locals {
  exadb_xs_resources = {
    exascale_db_storage_vaults = coalesce(try(module.exascale_db_storage_vault.exascale_db_storage_vault_resources, null), {})
    exadb_vm_clusters = { for key, cluster in oci_database_exadb_vm_cluster.these : key => {
      id             = cluster.id
      compartment_id = cluster.compartment_id
    } }
    database_homes      = try(module.common_database.database_resources.database_homes, {})
    databases           = try(module.common_database.database_resources.databases, {})
    pluggable_databases = try(module.common_database.database_resources.pluggable_databases, {})
  }
}

output "exadb_xs_resources" {
  description = "Minimal ExaDB-XS resource map for downstream dependency consumption."
  value       = var.enable_output ? local.exadb_xs_resources : null
}

output "exadb_xs_dependency" {
  description = "Alias of exadb_xs_resources for direct downstream dependency consumption."
  value       = var.enable_output ? local.exadb_xs_resources : null
}
