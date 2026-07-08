# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "cloud_exadata_infrastructures" {
  description = "The deployed Exadata Infrastructures in the OCI Database Service."
  value       = var.enable_output ? oci_database_cloud_exadata_infrastructure.these : null
}

output "cloud_vm_clusters" {
  description = "The deployed Cloud VM Clusters in the OCI Database Service."
  value       = var.enable_output ? oci_database_cloud_vm_cluster.these : null
}

output "database_homes" {
  description = "The deployed Databases Homes in the OCI Database Service."
  value       = var.enable_output ? oci_database_db_home.these : null
  sensitive   = true
}

output "databases" {
  description = "The deployed Databases in the OCI Database Service."
  value       = var.enable_output ? oci_database_database.these : null
  sensitive   = true
}

output "pluggable_databases" {
  description = "The deployed Pluggable Databases in the OCI Database Service."
  value       = var.enable_output ? oci_database_pluggable_database.these : null
  sensitive   = true
}

locals {
  cloud_exadata_database_resources = {
    cloud_exadata_infrastructures = { for k, v in oci_database_cloud_exadata_infrastructure.these : k => { "id" : v.id, "compartment_id" : v.compartment_id } }
    cloud_vm_clusters             = { for k, v in oci_database_cloud_vm_cluster.these : k => { "id" : v.id, "compartment_id" : v.compartment_id } }
    database_homes                = { for k, v in oci_database_db_home.these : k => { "id" : v.id, "compartment_id" : try(v.compartment_id, null) } }
    databases                     = { for k, v in oci_database_database.these : k => { "id" : v.id } }
    pluggable_databases           = { for k, v in oci_database_pluggable_database.these : k => { "id" : v.id } }
  }
}

output "cloud_exadata_database_resources" {
  description = "Minimal Cloud Exadata Database resources map for downstream dependency consumption."
  value       = var.enable_output ? local.cloud_exadata_database_resources : null
}

output "cloud_exadata_database_dependency" {
  description = "Alias for Orchestrator Cloud Exadata Database dependency consumption."
  value       = var.enable_output ? local.cloud_exadata_database_resources : null
}

output "exadata_database_resources" {
  description = "Alias for cloud_exadata_database_resources for Orchestrator integrations that still read the shorter Exadata output name."
  value       = var.enable_output ? local.cloud_exadata_database_resources : null
}

output "exadata_database_dependency" {
  description = "Alias for Orchestrator integrations that read the shorter Exadata dependency output name."
  value       = var.enable_output ? local.cloud_exadata_database_resources : null
}
