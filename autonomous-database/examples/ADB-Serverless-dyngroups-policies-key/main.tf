
# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "adb" {
  source                             = "../.."
  autonomous_databases_configuration = var.autonomous_databases_configuration
  secrets_dependency                 = var.secrets_dependency
  network_dependency                 = var.network_dependency
  vaults_dependency                  = var.vaults_dependency
  kms_dependency                     = var.kms_dependency
  tenancy_ocid                       = var.tenancy_ocid
  providers = {
    oci      = oci
    oci.home = oci.home
  }
}
