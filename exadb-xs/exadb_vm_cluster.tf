# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  vm_clusters_input       = try(coalesce(var.exadb_xs_configuration.exadb_vm_clusters, {}), {})
  default_compartment_id  = try(var.exadb_xs_configuration.default_compartment_id, null)
  default_defined_tags    = try(coalesce(var.exadb_xs_configuration.default_defined_tags, {}), {})
  default_freeform_tags   = try(coalesce(var.exadb_xs_configuration.default_freeform_tags, {}), {})
  storage_vaults_input    = try(coalesce(var.exadb_xs_configuration.exascale_db_storage_vaults, {}), {})
  compartments_input      = coalesce(var.compartments_dependency, {})
  subscriptions_input     = coalesce(var.subscription_dependency, {})
  network_subnets         = coalesce(try(var.network_dependency.subnets, null), {})
  network_security_groups = coalesce(try(var.network_dependency.network_security_groups, null), {})
  external_storage_vaults = coalesce(try(var.exadb_xs_dependency.exascale_db_storage_vaults, null), {})

  vm_clusters = {
    for key, cluster in local.vm_clusters_input : key => merge(cluster, {
      compartment_id_input   = cluster.compartment_id != null ? cluster.compartment_id : local.default_compartment_id
      compartment_id         = startswith(coalesce(cluster.compartment_id, local.default_compartment_id, ""), "ocid1") ? coalesce(cluster.compartment_id, local.default_compartment_id) : try(local.compartments_input[coalesce(cluster.compartment_id, local.default_compartment_id, "")].id, null)
      storage_vault_id_input = cluster.exascale_db_storage_vault_id
      storage_vault_id       = startswith(cluster.exascale_db_storage_vault_id, "ocid1") ? cluster.exascale_db_storage_vault_id : try(module.exascale_db_storage_vault.exascale_db_storage_vault_resources[cluster.exascale_db_storage_vault_id].id, try(local.external_storage_vaults[cluster.exascale_db_storage_vault_id].id, null))
      subnet_id              = startswith(cluster.subnet_id, "ocid1") ? cluster.subnet_id : try(local.network_subnets[cluster.subnet_id].id, null)
      backup_subnet_id       = startswith(cluster.backup_subnet_id, "ocid1") ? cluster.backup_subnet_id : try(local.network_subnets[cluster.backup_subnet_id].id, null)
      nsg_ids                = [for id in cluster.nsg_ids : startswith(id, "ocid1") ? id : try(local.network_security_groups[id].id, null)]
      backup_network_nsg_ids = [for id in cluster.backup_network_nsg_ids : startswith(id, "ocid1") ? id : try(local.network_security_groups[id].id, null)]
      subscription_id_input  = cluster.subscription_id
      subscription_id = cluster.subscription_id == null ? null : (
        startswith(cluster.subscription_id, "ocid1") ? cluster.subscription_id : try(local.subscriptions_input[cluster.subscription_id].id, null)
      )
      node_resources = { for name in cluster.node_names : trimspace(name) => trimspace(name) }
      defined_tags   = coalesce(cluster.defined_tags, local.default_defined_tags)
      freeform_tags  = merge(local.cislz_module_tag, coalesce(cluster.freeform_tags, local.default_freeform_tags))
    })
  }
}

resource "oci_database_exadb_vm_cluster" "these" {
  depends_on = [module.exascale_db_storage_vault]
  for_each   = local.vm_clusters

  availability_domain          = each.value.availability_domain
  backup_subnet_id             = each.value.backup_subnet_id
  compartment_id               = each.value.compartment_id
  display_name                 = each.value.display_name
  exascale_db_storage_vault_id = each.value.storage_vault_id
  grid_image_id                = each.value.grid_image_id
  hostname                     = each.value.hostname
  shape                        = each.value.shape
  ssh_public_keys              = each.value.ssh_public_keys
  subnet_id                    = each.value.subnet_id

  backup_network_nsg_ids     = length(each.value.backup_network_nsg_ids) > 0 ? each.value.backup_network_nsg_ids : null
  cluster_name               = each.value.cluster_name
  defined_tags               = each.value.defined_tags
  domain                     = each.value.domain
  freeform_tags              = each.value.freeform_tags
  license_model              = each.value.license_model
  nsg_ids                    = length(each.value.nsg_ids) > 0 ? each.value.nsg_ids : null
  private_zone_id            = each.value.private_zone_id
  scan_listener_port_tcp     = each.value.scan_listener_port_tcp
  scan_listener_port_tcp_ssl = each.value.scan_listener_port_tcp_ssl
  shape_attribute            = each.value.shape_attribute
  subscription_id            = each.value.subscription_id
  system_version             = each.value.system_version
  time_zone                  = each.value.time_zone
  security_attributes = length(try(each.value.security.zpr_attributes, [])) > 0 ? merge([
    for attribute in each.value.security.zpr_attributes : {
      "${attribute.namespace}.${attribute.attr_name}.value" = attribute.attr_value
      "${attribute.namespace}.${attribute.attr_name}.mode"  = attribute.mode
    }
  ]...) : null

  node_config {
    enabled_ecpu_count_per_node              = each.value.node_config.enabled_ecpu_count_per_node
    total_ecpu_count_per_node                = each.value.node_config.total_ecpu_count_per_node
    vm_file_system_storage_size_gbs_per_node = each.value.node_config.vm_file_system_storage_size_gbs_per_node
  }

  dynamic "node_resource" {
    for_each = each.value.node_resources
    content {
      node_name = node_resource.value
    }
  }

  dynamic "data_collection_options" {
    for_each = each.value.data_collection_options == null ? [] : [each.value.data_collection_options]
    content {
      is_diagnostics_events_enabled = data_collection_options.value.is_diagnostics_events_enabled
      is_health_monitoring_enabled  = data_collection_options.value.is_health_monitoring_enabled
      is_incident_logs_enabled      = data_collection_options.value.is_incident_logs_enabled
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.compartment_id != null && can(regex("^ocid1\\.(compartment|tenancy)\\.", each.value.compartment_id))
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].compartment_id must be a compartment OCID, the tenancy OCID, or a key in compartments_dependency."
    }
    precondition {
      condition = each.value.storage_vault_id != null && (
        contains(keys(local.storage_vaults_input), each.value.storage_vault_id_input) ||
        can(regex("^ocid1\\.exascaledbstoragevault\\.", each.value.storage_vault_id))
      )
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].exascale_db_storage_vault_id must be an Exascale DB Storage Vault OCID, a local storage-vault key, or a key in exadb_xs_dependency.exascale_db_storage_vaults."
    }
    precondition {
      condition     = each.value.subnet_id != null && can(regex("^ocid1\\.subnet\\.", each.value.subnet_id))
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }
    precondition {
      condition     = each.value.backup_subnet_id != null && can(regex("^ocid1\\.subnet\\.", each.value.backup_subnet_id))
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].backup_subnet_id must be a subnet OCID or a key in network_dependency.subnets."
    }
    precondition {
      condition     = alltrue([for id in each.value.nsg_ids : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].nsg_ids must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }
    precondition {
      condition     = alltrue([for id in each.value.backup_network_nsg_ids : id != null && can(regex("^ocid1\\.networksecuritygroup\\.", id))])
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].backup_network_nsg_ids must contain network security group OCIDs or keys in network_dependency.network_security_groups."
    }
    precondition {
      condition     = each.value.subscription_id_input == null ? true : (each.value.subscription_id != null && can(regex("^ocid1\\.", each.value.subscription_id)))
      error_message = "exadb_xs_configuration.exadb_vm_clusters[*].subscription_id must be an OCID or a key in subscription_dependency."
    }

    ignore_changes = [
      grid_image_id,
      system_version,
      defined_tags,
    ]
  }
}
