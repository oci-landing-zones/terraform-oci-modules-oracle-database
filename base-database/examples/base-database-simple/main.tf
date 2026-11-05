# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "base_database" {
  source = "../.."

  db_systems_configuration = var.db_systems_configuration
  tenancy_ocid             = var.tenancy_ocid
}
