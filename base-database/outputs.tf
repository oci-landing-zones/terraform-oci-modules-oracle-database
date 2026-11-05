# Copyright (c) 2023, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "db_systems" {
  description = "The deployed Base Database Service DB Systems."
  value = var.enable_output ? {
    for key, db_system in oci_database_db_system.these : key => {
      id             = db_system.id
      compartment_id = db_system.compartment_id
      display_name   = db_system.display_name
      shape          = db_system.shape
      cpu_core_count = db_system.cpu_core_count
      db_home_id     = try(db_system.db_home[0].id, null)
      database_id    = try(db_system.db_home[0].database[0].id, null)
      db_name        = try(db_system.db_home[0].database[0].db_name, null)
      pdb_name       = try(db_system.db_home[0].database[0].pdb_name, null)
    }
  } : null
}

output "additional_pdbs" {
  description = "The additional Pluggable Databases managed by this module."
  value = var.enable_output ? {
    for key, pdb in oci_database_pluggable_database.these : key => {
      id                    = pdb.id
      compartment_id        = pdb.compartment_id
      pdb_name              = pdb.pdb_name
      container_database_id = pdb.container_database_id
      state                 = pdb.state
    }
  } : null
}

locals {
  db_system_resources = {
    db_systems = {
      for key, db_system in oci_database_db_system.these : key => {
        id             = db_system.id
        compartment_id = db_system.compartment_id
      }
    }
  }
}

output "db_system_resources" {
  description = "Minimal DB System resource map for downstream dependency consumption."
  value       = var.enable_output ? local.db_system_resources : null
}

output "db_system_dependency" {
  description = "Alias of db_system_resources for direct common-database consumption."
  value       = var.enable_output ? local.db_system_resources.db_systems : null
}
