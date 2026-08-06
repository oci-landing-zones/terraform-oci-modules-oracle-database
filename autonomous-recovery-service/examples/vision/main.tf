
# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "vision" {
  source = "../.."
  providers = {
    oci      = oci
    oci.home = oci.home
  }
  tenancy_ocid = var.tenancy_ocid
  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
}

