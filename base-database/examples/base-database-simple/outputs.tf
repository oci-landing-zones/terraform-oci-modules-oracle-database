# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "db_systems" {
  description = "The deployed Base Database Service DB Systems."
  value       = module.base_database.db_systems
}
