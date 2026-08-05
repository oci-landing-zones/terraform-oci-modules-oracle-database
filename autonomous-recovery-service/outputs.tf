# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "autonomous_recovery_service_subnets" {
    description = "The Autonomous Recovery Service subnets."
    value       = var.enable_output ? oci_recovery_recovery_service_subnet.these : null
}

output "autonomous_recovery_service_protection_policies" {
    description = "The Autonomous Recovery Service protection policies"
    value       = var.enable_output ? oci_recovery_protection_policy.these : null
}

output "autonomous_recovery_service_protected_databases" {
    description = "The Autonomous Recovery Service protected databases"
    value       = var.enable_output ? oci_recovery_protected_database.these : null
} 