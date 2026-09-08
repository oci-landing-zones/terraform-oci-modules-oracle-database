# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


variable "tenancy_ocid" {}
variable "region" { description = "Your tenancy region" }
variable "user_ocid" { default = "" }
variable "fingerprint" { default = "" }
variable "private_key_path" { default = "" }
variable "private_key_password" { default = "" }


variable "compartments_dependency" {
  type    = any
  default = null
}
variable "subscription_dependency" {
  type    = any
  default = null
}
variable "network_dependency" {
  type    = any
  default = null
}
variable "secrets_dependency" {
  type    = any
  default = null
}
variable "default_compartment_id" {
  type    = any
  default = null
}
variable "default_defined_tags" { default = null }
variable "default_freeform_tags" { default = null }
variable "cloud_exadata_infrastructures_configuration" {
  type    = any
  default = null
}
variable "cloud_vm_clusters_configuration" {
  type    = any
  default = null
}
# Enable DM HOME creation in the example
variable "cloud_db_homes_configuration" {
  description = "DB homes to be created."
  type        = any
  default     = null
}
# Enable CDB+PDB creation in the example
variable "databases_configuration" {
  description = "Databases (CDB + initial PDB) to create for this example. Keys are arbitrary unique names."
  type        = any
  default     = null
}
# Enable CDB+PDB creation in the example
variable "pluggable_databases_configuration" {
  description = "Additional pluggable databases to create for this example."
  type        = any
  default     = null
}
