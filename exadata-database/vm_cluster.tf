# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  cloud_exadata_infrastructures_input      = try(var.cloud_exadata_infrastructures_configuration.cloud_exadata_infrastructures, {})
  cloud_exadata_infrastructures_dependency = coalesce(try(var.exadata_database_dependency.cloud_exadata_infrastructures, null), {})
  compartments_dependency_input            = var.compartments_dependency != null ? var.compartments_dependency : {}
  default_compartment_id_resolves = var.default_compartment_id != null ? (
    can(regex("^ocid1\\.(compartment|tenancy)\\.", var.default_compartment_id)) ||
    contains(keys(local.compartments_dependency_input), var.default_compartment_id)
  ) : false

  cloud_vm_clusters = { for vm_key, vm in coalesce(var.cloud_vm_clusters_configuration, {}) : vm_key => merge(vm, {
    subscription_id_input = vm.subscription_id
    exadata_infra_id      = can(regex("^ocid1\\.cloudexadatainfrastructure.", vm.exadata_infrastructure_id)) ? vm.exadata_infrastructure_id : try(oci_database_cloud_exadata_infrastructure.these[vm.exadata_infrastructure_id].id, var.exadata_database_dependency.cloud_exadata_infrastructures[vm.exadata_infrastructure_id].id, null)
    compartment_id = vm.compartment_id != null ? (
      can(regex("^ocid1\\.(compartment|tenancy)\\.", vm.compartment_id)) ? vm.compartment_id : try(var.compartments_dependency[vm.compartment_id].id, null)) : try(coalesce(try(oci_database_cloud_exadata_infrastructure.these[vm.exadata_infrastructure_id].compartment_id, null), try(var.exadata_database_dependency.cloud_exadata_infrastructures[vm.exadata_infrastructure_id].compartment_id, null), (
        can(regex("^ocid1\\.(compartment|tenancy)\\.", var.default_compartment_id)) ? var.default_compartment_id : try(var.compartments_dependency[var.default_compartment_id].id, null)
    )), null)

    subnet_id              = can(regex("^ocid1\\.subnet", vm.subnet_id)) ? vm.subnet_id : try(var.network_dependency.subnets[vm.subnet_id].id, null)
    backup_subnet_id       = can(regex("^ocid1\\.subnet", vm.backup_subnet_id)) ? vm.backup_subnet_id : try(var.network_dependency.subnets[vm.backup_subnet_id].id, null)
    nsg_ids                = [for id in coalesce(vm.nsg_ids, []) : can(regex("^ocid1\\.networksecuritygroup", id)) ? id : try(var.network_dependency.network_security_groups[id].id, null)]
    backup_network_nsg_ids = [for id in coalesce(vm.backup_network_nsg_ids, []) : can(regex("^ocid1\\.networksecuritygroup", id)) ? id : try(var.network_dependency.network_security_groups[id].id, null)]
    subscription_id        = can(regex("^ocid1\\.", vm.subscription_id)) ? vm.subscription_id : try(var.subscription_dependency[vm.subscription_id].id, null)
  }) }

  cloud_vm_clusters_with_db_server_lookup = {
    for vm_key, vm in coalesce(var.cloud_vm_clusters_configuration, {}) :
    vm_key => local.cloud_vm_clusters[vm_key]
    if contains(coalesce(vm.db_servers, []), "ALL") && (
      can(regex("^ocid1\\.cloudexadatainfrastructure.", vm.exadata_infrastructure_id)) ||
      contains(keys(local.cloud_exadata_infrastructures_input), vm.exadata_infrastructure_id) ||
      contains(keys(local.cloud_exadata_infrastructures_dependency), vm.exadata_infrastructure_id)
      ) && (vm.compartment_id != null ? (
        can(regex("^ocid1\\.(compartment|tenancy)\\.", vm.compartment_id)) ||
        contains(keys(local.compartments_dependency_input), vm.compartment_id)
        ) : (try(local.cloud_exadata_infrastructures_input[vm.exadata_infrastructure_id].compartment_id, null) != null ? (
          can(regex("^ocid1\\.(compartment|tenancy)\\.", local.cloud_exadata_infrastructures_input[vm.exadata_infrastructure_id].compartment_id)) ||
          contains(keys(local.compartments_dependency_input), local.cloud_exadata_infrastructures_input[vm.exadata_infrastructure_id].compartment_id)
          ) : (
          try(local.cloud_exadata_infrastructures_dependency[vm.exadata_infrastructure_id].compartment_id, null) != null ? can(regex("^ocid1\\.(compartment|tenancy)\\.", local.cloud_exadata_infrastructures_dependency[vm.exadata_infrastructure_id].compartment_id)) : local.default_compartment_id_resolves
        )
      )
    )
  }
}

data "oci_database_db_servers" "these" {
  for_each                  = local.cloud_vm_clusters_with_db_server_lookup
  compartment_id            = each.value.compartment_id
  exadata_infrastructure_id = each.value.exadata_infra_id
}

resource "oci_database_cloud_vm_cluster" "these" {
  depends_on = [oci_database_cloud_exadata_infrastructure.these]

  for_each = local.cloud_vm_clusters

  cloud_exadata_infrastructure_id = each.value.exadata_infra_id
  compartment_id                  = each.value.compartment_id
  display_name                    = each.value.display_name
  cpu_core_count                  = each.value.cpu_core_count
  gi_version                      = each.value.gi_version
  hostname                        = each.value.hostname
  ssh_public_keys                 = each.value.ssh_public_keys
  subnet_id                       = each.value.subnet_id
  backup_subnet_id                = each.value.backup_subnet_id
  data_storage_size_in_tbs        = each.value.data_storage_size_in_tbs
  db_node_storage_size_in_gbs     = each.value.db_node_storage_size_in_gbs
  memory_size_in_gbs              = each.value.memory_size_in_gbs

  # Optional
  backup_network_nsg_ids      = length(each.value.backup_network_nsg_ids) > 0 ? each.value.backup_network_nsg_ids : null
  defined_tags                = each.value.defined_tags != null ? each.value.defined_tags : var.default_defined_tags
  freeform_tags               = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.default_freeform_tags)
  is_local_backup_enabled     = each.value.is_local_backup_enabled
  is_sparse_diskgroup_enabled = each.value.is_sparse_diskgroup_enabled
  nsg_ids                     = length(each.value.nsg_ids) > 0 ? each.value.nsg_ids : null
  scan_listener_port_tcp      = each.value.scan_listener_port_tcp
  scan_listener_port_tcp_ssl  = each.value.scan_listener_port_tcp_ssl
  time_zone                   = each.value.time_zone
  cluster_name                = each.value.cluster_name
  data_storage_percentage     = each.value.data_storage_percentage
  db_servers                  = contains(coalesce(each.value.db_servers, []), "ALL") && contains(keys(data.oci_database_db_servers.these), each.key) ? [for db_server in data.oci_database_db_servers.these[each.key].db_servers : db_server.id] : each.value.db_servers
  domain                      = each.value.domain
  license_model               = each.value.license_model
  ocpu_count                  = each.value.ocpu_count
  private_zone_id             = each.value.private_zone_id
  subscription_id             = each.value.subscription_id
  system_version              = each.value.system_version
  vm_cluster_type             = each.value.vm_cluster_type

  security_attributes = try(each.value.security.zpr_attributes, null) != null ? merge([for a in each.value.security.zpr_attributes : { "${a.namespace}.${a.attr_name}.value" : a.attr_value, "${a.namespace}.${a.attr_name}.mode" : a.mode }]...) : null

  dynamic "data_collection_options" {
    for_each = each.value.data_collection_options != null ? [each.value.data_collection_options] : []
    content {
      is_diagnostics_events_enabled = data_collection_options.value.is_diagnostics_events_enabled
      is_health_monitoring_enabled  = data_collection_options.value.is_health_monitoring_enabled
      is_incident_logs_enabled      = data_collection_options.value.is_incident_logs_enabled
    }
  }

  dynamic "cloud_automation_update_details" {
    for_each = each.value.cloud_automation_update_details != null ? [each.value.cloud_automation_update_details] : []
    content {
      dynamic "apply_update_time_preference" {
        for_each = cloud_automation_update_details.value.apply_update_time_preference != null ? [cloud_automation_update_details.value.apply_update_time_preference] : []
        content {
          apply_update_preferred_start_time = apply_update_time_preference.value.apply_update_preferred_start_time
          apply_update_preferred_end_time   = apply_update_time_preference.value.apply_update_preferred_end_time
        }
      }
      dynamic "freeze_period" {
        for_each = cloud_automation_update_details.value.freeze_period != null ? [cloud_automation_update_details.value.freeze_period] : []
        content {
          freeze_period_start_time = freeze_period.value.freeze_period_start_time
          freeze_period_end_time   = freeze_period.value.freeze_period_end_time
        }
      }
      is_early_adoption_enabled = cloud_automation_update_details.value.is_early_adoption_enabled
      is_freeze_period_enabled  = cloud_automation_update_details.value.is_freeze_period_enabled
    }
  }

  dynamic "file_system_configuration_details" {
    for_each = each.value.file_system_configuration_details != null ? each.value.file_system_configuration_details : {}
    content {
      file_system_size_gb = file_system_configuration_details.value.file_system_size_gb
      mount_point         = file_system_configuration_details.value.mount_point
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.exadata_infra_id != null && can(regex("^ocid1\\.cloudexadatainfrastructure\\.", each.value.exadata_infra_id))
      error_message = "exadata_infrastructure_id must be a Cloud Exadata infrastructure OCID or a key in exadata_database_dependency.cloud_exadata_infrastructures."
    }

    precondition {
      condition     = each.value.compartment_id != null && can(regex("^ocid1\\.(compartment|tenancy)\\.", each.value.compartment_id))
      error_message = "compartment_id must be a compartment OCID, the tenancy OCID for the root compartment, or a key in compartments_dependency."
    }

    precondition {
      condition     = each.value.subnet_id != null && can(regex("^ocid1\\.subnet\\.", each.value.subnet_id))
      error_message = "subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }

    precondition {
      condition     = each.value.backup_subnet_id != null && can(regex("^ocid1\\.subnet\\.", each.value.backup_subnet_id))
      error_message = "backup_subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }

    precondition {
      condition     = alltrue([for id in each.value.nsg_ids : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "nsg_ids must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }

    precondition {
      condition     = alltrue([for id in each.value.backup_network_nsg_ids : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "backup_network_nsg_ids must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }

    precondition {
      condition     = each.value.subscription_id_input == null ? true : (each.value.subscription_id != null && can(regex("^ocid1\\.", each.value.subscription_id)))
      error_message = "subscription_id must be an OCID or a key in subscription_dependency."
    }

    ignore_changes = [
      gi_version,
      system_version,
      defined_tags,
    ]
  }
}
