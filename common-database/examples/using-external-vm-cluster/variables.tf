# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "vm_cluster_dependency" {
  description = "Existing Cloud VM Clusters keyed by the logical names used in cloud_db_homes_configuration."
  type        = any
}

variable "cloud_db_homes_configuration" {
  type = any
}

variable "databases_configuration" {
  type = any
}

variable "pluggable_databases_configuration" {
  type    = any
  default = null
}

variable "kms_dependency" {
  type    = any
  default = null
}

variable "recovery_service_dependency" {
  type    = any
  default = null
}

variable "default_defined_tags" {
  type    = map(string)
  default = {}
}

variable "default_freeform_tags" {
  type    = map(string)
  default = {}
}
