# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "recovery_service_subnets" {
  description = "Recovery Service subnets created by the ARS module."
  value       = module.autonomous_recovery_service.autonomous_recovery_service_subnets
}

output "protection_policies" {
  description = "Protection policies created by the ARS module."
  value       = module.autonomous_recovery_service.autonomous_recovery_service_protection_policies
}

output "cloud_exadata_database_resources" {
  description = "Exadata Database resources created by the Exadata module."
  sensitive   = true
  value = {
    databases = module.exadb_d.databases
  }
}
