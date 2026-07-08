# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains

# NOTE!!! Note that the order of the results returned can change if availability domains are added or removed; 
# therefore, do not create a dependency on the list order.
locals {
  cloud_exadata_infrastructures = {
    for infra_key, infra in coalesce(try(var.cloud_exadata_infrastructures_configuration.cloud_exadata_infrastructures, null), {}) :
    infra_key => merge(infra, {
      compartment_id_input = infra.compartment_id != null ? infra.compartment_id : var.default_compartment_id
      compartment_id = infra.compartment_id != null ? (
        can(regex("^ocid1\\.compartment", infra.compartment_id)) ? infra.compartment_id : try(var.compartments_dependency[infra.compartment_id].id, null)
        ) : (
        var.default_compartment_id != null ? (
          can(regex("^ocid1\\.compartment", var.default_compartment_id)) ? var.default_compartment_id : try(var.compartments_dependency[var.default_compartment_id].id, null)
        ) : null
      )
      subscription_id_input = infra.subscription_id
      subscription_id = infra.subscription_id == null ? null : (
        can(regex("^ocid1\\.", infra.subscription_id)) ? infra.subscription_id : try(var.subscription_dependency[infra.subscription_id].id, null)
      )
    })
  }
}

data "oci_identity_availability_domains" "ads" {
  for_each       = { for k, v in local.cloud_exadata_infrastructures : k => v if v.compartment_id != null }
  compartment_id = each.value.compartment_id
}


resource "oci_database_cloud_exadata_infrastructure" "these" {
  for_each = local.cloud_exadata_infrastructures

  display_name   = each.value.display_name
  shape          = each.value.shape
  compartment_id = each.value.compartment_id
  availability_domain = each.value.availability_domain != null ? each.value.availability_domain : (
    try(sort([for ad in data.oci_identity_availability_domains.ads[each.key].availability_domains : ad.name])[0], null)
  )
  compute_count = each.value.compute_count
  dynamic "customer_contacts" {
    for_each = each.value.customer_contacts != null ? [each.value.customer_contacts] : []
    content {
      email = customer_contacts.value.email
    }
  }

  database_server_type = each.value.database_server_type
  defined_tags         = each.value.defined_tags != null ? each.value.defined_tags : var.default_defined_tags
  freeform_tags        = merge(each.value.freeform_tags != null ? each.value.freeform_tags : var.default_freeform_tags)

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : var.cloud_exadata_infrastructures_configuration.default_maintenance_window != null ? [var.cloud_exadata_infrastructures_configuration.default_maintenance_window] : []
    content {
      custom_action_timeout_in_mins = try(maintenance_window.value.custom_action_timeout_in_mins, null)
      dynamic "days_of_week" {
        for_each = maintenance_window.value.days_of_week != null ? maintenance_window.value.days_of_week : []
        content {
          name = days_of_week.value
        }
      }
      hours_of_day                     = maintenance_window.value.hours_of_day != null ? (length(maintenance_window.value.hours_of_day) > 0 ? maintenance_window.value.hours_of_day : null) : null
      is_custom_action_timeout_enabled = try(maintenance_window.value.is_custom_action_timeout_enabled, null)
      is_monthly_patching_enabled      = try(maintenance_window.value.is_monthly_patching_enabled, null)
      lead_time_in_weeks               = maintenance_window.value.lead_time_in_weeks != null ? maintenance_window.value.lead_time_in_weeks : null

      dynamic "months" {
        for_each = maintenance_window.value.months != null ? maintenance_window.value.months : []
        content {
          name = months.value
        }
      }
      patching_mode  = try(maintenance_window.value.patching_mode, null)
      preference     = try(maintenance_window.value.preference, null)
      weeks_of_month = maintenance_window.value.weeks_of_month != null ? (length(maintenance_window.value.weeks_of_month) > 0 ? maintenance_window.value.weeks_of_month : null) : null
    }
  }

  storage_count       = each.value.storage_count
  storage_server_type = each.value.storage_server_type
  subscription_id     = each.value.subscription_id

  lifecycle {
    precondition {
      condition     = each.value.compartment_id != null && can(regex("^ocid1\\.compartment\\.", each.value.compartment_id))
      error_message = "compartment_id must be a compartment OCID or a key in compartments_dependency."
    }

    precondition {
      condition     = each.value.subscription_id_input == null ? true : (each.value.subscription_id != null && can(regex("^ocid1\\.", each.value.subscription_id)))
      error_message = "subscription_id must be an OCID or a key in subscription_dependency."
    }
  }
}
