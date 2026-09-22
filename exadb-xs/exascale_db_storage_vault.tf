# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  exascale_db_storage_vaults_configuration = var.exadb_xs_configuration == null ? null : {
    default_compartment_id     = try(var.exadb_xs_configuration.default_compartment_id, null)
    default_defined_tags       = try(coalesce(var.exadb_xs_configuration.default_defined_tags, {}), {})
    default_freeform_tags      = try(coalesce(var.exadb_xs_configuration.default_freeform_tags, {}), {})
    exascale_db_storage_vaults = try(coalesce(var.exadb_xs_configuration.exascale_db_storage_vaults, {}), {})
  }
}

module "exascale_db_storage_vault" {
  source = "../exascale-db-storage-vault"

  module_name = "${var.module_name}-exascale-db-storage-vault"
  # The parent must resolve locally created vault IDs even when its public
  # outputs are disabled. The parent itself still gates every public output.
  enable_output                            = true
  exascale_db_storage_vaults_configuration = local.exascale_db_storage_vaults_configuration
  compartments_dependency                  = var.compartments_dependency
  subscription_dependency                  = var.subscription_dependency
  exadata_infrastructure_dependency        = var.exadata_infrastructure_dependency
}
