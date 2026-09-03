# Copyright (c) 2023, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "autonomous_databases" {
  description = "The Autonomous Databases"
  value       = var.enable_output ? { for k, v in oci_database_autonomous_database.these : k => { "display_name" : v.display_name, "ocid" : v.id, "ecpu_count" : v.compute_count, "db_workload" : v.db_workload } } : null
}

locals {
  autonomous_databases_resources = {
    autonomous_databases = { for k, v in oci_database_autonomous_database.these : k => { "id" : v.id, "compartment_id" : v.compartment_id, "display_name" : v.display_name, "db_workload" : v.db_workload, "ecpu_count" : v.compute_count } }
  }
}

output "autonomous_databases_resources" {
  description = "Minimal Autonomous Databases resources map for downstream dependency consumption."
  value       = var.enable_output ? local.autonomous_databases_resources : null
}

output "autonomous_database_resources" {
  description = "Alias for autonomous_databases_resources for integrations that read the singular Autonomous Database output name."
  value       = var.enable_output ? local.autonomous_databases_resources : null
}

output "autonomous_databases_dependency" {
  description = "Alias for Orchestrator Autonomous Databases dependency consumption."
  value       = var.enable_output ? local.autonomous_databases_resources : null
}
