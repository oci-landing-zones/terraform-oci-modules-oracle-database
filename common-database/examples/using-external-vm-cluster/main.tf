# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "common_database" {
  source = "../.."

  vm_cluster_dependency = var.vm_cluster_dependency

  cloud_db_homes_configuration      = var.cloud_db_homes_configuration
  databases_configuration           = var.databases_configuration
  pluggable_databases_configuration = var.pluggable_databases_configuration

  kms_dependency              = var.kms_dependency
  recovery_service_dependency = var.recovery_service_dependency
  default_defined_tags        = var.default_defined_tags
  default_freeform_tags       = var.default_freeform_tags
}
