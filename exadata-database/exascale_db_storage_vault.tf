# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  exascale_db_storage_vault_exadata_infrastructure_dependency = merge(
    coalesce(try(var.exadata_database_dependency.cloud_exadata_infrastructures, null), {}),
    {
      for key, infrastructure in oci_database_cloud_exadata_infrastructure.these : key => {
        id             = infrastructure.id
        compartment_id = infrastructure.compartment_id
      }
    }
  )
}

module "exascale_db_storage_vault" {
  source = "../exascale-db-storage-vault"

  module_name                              = "${var.module_name}-exascale-db-storage-vault"
  enable_output                            = var.enable_output
  exascale_db_storage_vaults_configuration = var.exascale_db_storage_vaults_configuration
  compartments_dependency                  = var.compartments_dependency
  subscription_dependency                  = var.subscription_dependency
  exadata_infrastructure_dependency        = local.exascale_db_storage_vault_exadata_infrastructure_dependency
}
