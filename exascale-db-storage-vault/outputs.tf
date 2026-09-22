# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "exascale_db_storage_vaults" {
  description = "The deployed Exascale DB Storage Vault resources."
  value       = var.enable_output ? oci_database_exascale_db_storage_vault.these : null
}

locals {
  exascale_db_storage_vault_resources = {
    for key, vault in oci_database_exascale_db_storage_vault.these : key => {
      id             = vault.id
      compartment_id = vault.compartment_id
    }
  }
}

output "exascale_db_storage_vault_resources" {
  description = "Minimal vault map for downstream dependency consumption."
  value       = var.enable_output ? local.exascale_db_storage_vault_resources : null
}

output "exascale_db_storage_vault_dependency" {
  description = "Alias of exascale_db_storage_vault_resources for downstream module consumption."
  value       = var.enable_output ? local.exascale_db_storage_vault_resources : null
}
