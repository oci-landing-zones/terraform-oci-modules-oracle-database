# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "autonomous_recovery_service" {
  source = "../.."

  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
  compartments_dependency                   = var.compartments_dependency
  network_dependency                        = var.network_dependency
}

locals {
  databases_configuration_with_ars = {
    for database_key, database_config in coalesce(var.databases_configuration, {}) : database_key => merge(database_config, {
      database = merge(database_config.database, {
        db_backup_config = {
          auto_backup_enabled     = true
          auto_backup_window      = "SLOT_ONE"
          auto_full_backup_day    = "SUNDAY"
          auto_full_backup_window = "SLOT_TWO"
          backup_deletion_policy  = "DELETE_AFTER_RETENTION_PERIOD"
          backup_destination_details = {
            type           = "DBRS"
            dbrs_policy_id = var.database_recovery_service_policy_keys[database_key]
          }
          run_immediate_full_backup = false
        }
      })
    })
  }
}

module "exadb_d" {
  source = "../../../exadata-database"

  compartments_dependency     = var.compartments_dependency
  subscription_dependency     = var.subscription_dependency
  network_dependency          = var.network_dependency
  recovery_service_dependency = module.autonomous_recovery_service.protection_policies
  default_compartment_id      = var.default_compartment_id
  default_defined_tags        = var.default_defined_tags
  default_freeform_tags       = var.default_freeform_tags
  databases_configuration     = local.databases_configuration_with_ars
}
