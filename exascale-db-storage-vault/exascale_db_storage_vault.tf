# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  default_compartment_id = try(var.exascale_db_storage_vaults_configuration.default_compartment_id, null)
  default_defined_tags   = try(coalesce(var.exascale_db_storage_vaults_configuration.default_defined_tags, {}), {})
  default_freeform_tags  = try(coalesce(var.exascale_db_storage_vaults_configuration.default_freeform_tags, {}), {})

  storage_vaults_input          = try(coalesce(var.exascale_db_storage_vaults_configuration.exascale_db_storage_vaults, {}), {})
  compartments_input            = coalesce(var.compartments_dependency, {})
  subscriptions_input           = coalesce(var.subscription_dependency, {})
  exadata_infrastructures_input = coalesce(var.exadata_infrastructure_dependency, {})

  storage_vaults = {
    for key, vault in local.storage_vaults_input : key => merge(vault, {
      compartment_id_input            = vault.compartment_id != null ? vault.compartment_id : local.default_compartment_id
      compartment_id                  = startswith(coalesce(vault.compartment_id, local.default_compartment_id, ""), "ocid1") ? coalesce(vault.compartment_id, local.default_compartment_id) : try(local.compartments_input[coalesce(vault.compartment_id, local.default_compartment_id, "")].id, null)
      exadata_infrastructure_id_input = vault.exadata_infrastructure_id
      exadata_infrastructure_id = vault.exadata_infrastructure_id == null ? null : (
        startswith(vault.exadata_infrastructure_id, "ocid1") ? vault.exadata_infrastructure_id : try(local.exadata_infrastructures_input[vault.exadata_infrastructure_id].id, null)
      )
      subscription_id_input = vault.subscription_id
      subscription_id = vault.subscription_id == null ? null : (
        startswith(vault.subscription_id, "ocid1") ? vault.subscription_id : try(local.subscriptions_input[vault.subscription_id].id, null)
      )
      defined_tags  = coalesce(vault.defined_tags, local.default_defined_tags)
      freeform_tags = merge(local.cislz_module_tag, coalesce(vault.freeform_tags, local.default_freeform_tags))
    })
  }
}

resource "oci_database_exascale_db_storage_vault" "these" {
  for_each = local.storage_vaults

  availability_domain               = each.value.availability_domain
  compartment_id                    = each.value.compartment_id
  display_name                      = each.value.display_name
  additional_flash_cache_in_percent = each.value.additional_flash_cache_in_percent
  autoscale_limit_in_gbs            = each.value.autoscale_limit_in_gbs
  description                       = each.value.description
  exadata_infrastructure_id         = each.value.exadata_infrastructure_id
  is_autoscale_enabled              = each.value.is_autoscale_enabled
  subscription_id                   = each.value.subscription_id
  time_zone                         = each.value.time_zone
  defined_tags                      = each.value.defined_tags
  freeform_tags                     = each.value.freeform_tags

  high_capacity_database_storage {
    total_size_in_gbs = each.value.high_capacity_database_storage_gbs
  }

  lifecycle {
    precondition {
      condition     = each.value.compartment_id != null && can(regex("^ocid1\\.(compartment|tenancy)\\.", each.value.compartment_id))
      error_message = "exascale_db_storage_vaults_configuration.exascale_db_storage_vaults[*].compartment_id must be a compartment OCID, the tenancy OCID, or a key in compartments_dependency."
    }
    precondition {
      condition     = each.value.exadata_infrastructure_id_input == null ? true : (each.value.exadata_infrastructure_id != null && can(regex("^ocid1\\.(cloudexadatainfrastructure|exadatainfrastructure)\\.", each.value.exadata_infrastructure_id)))
      error_message = "exascale_db_storage_vaults_configuration.exascale_db_storage_vaults[*].exadata_infrastructure_id must be a Cloud Exadata Infrastructure or Exadata Cloud@Customer Infrastructure OCID, or a key in exadata_infrastructure_dependency."
    }
    precondition {
      condition     = each.value.subscription_id_input == null ? true : (each.value.subscription_id != null && can(regex("^ocid1\\.", each.value.subscription_id)))
      error_message = "exascale_db_storage_vaults_configuration.exascale_db_storage_vaults[*].subscription_id must be an OCID or a key in subscription_dependency."
    }

    ignore_changes = [defined_tags]
  }
}
