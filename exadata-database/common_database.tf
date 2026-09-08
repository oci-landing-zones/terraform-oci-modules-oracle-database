# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  common_database_dependency = {
    database_homes      = coalesce(try(var.exadata_database_dependency.database_homes, null), {})
    databases           = coalesce(try(var.exadata_database_dependency.databases, null), {})
    pluggable_databases = coalesce(try(var.exadata_database_dependency.pluggable_databases, null), {})
  }

  common_database_vm_cluster_dependency = merge(
    coalesce(try(var.exadata_database_dependency.cloud_vm_clusters, null), {}),
    { for key, vm_cluster in oci_database_cloud_vm_cluster.these : key => {
      id             = vm_cluster.id
      compartment_id = vm_cluster.compartment_id
    } }
  )
}

module "common_database" {
  source = "../common-database"

  module_name                       = "${var.module_name}-common-database"
  enable_output                     = var.enable_output
  database_dependency               = local.common_database_dependency
  vm_cluster_dependency             = local.common_database_vm_cluster_dependency
  kms_dependency                    = var.kms_dependency
  recovery_service_dependency       = var.recovery_service_dependency
  secrets_dependency                = var.secrets_dependency
  default_defined_tags              = var.default_defined_tags
  default_freeform_tags             = var.default_freeform_tags
  cloud_db_homes_configuration      = var.cloud_db_homes_configuration
  databases_configuration           = var.databases_configuration
  pluggable_databases_configuration = var.pluggable_databases_configuration
}
