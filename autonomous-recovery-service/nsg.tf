locals {
  inject_into_existing_vcns = {for k, v in var.autonomous_recovery_service_configuration.recovery_subnets : k => {
    vcn_id = startswith(v.vcn_id, "ocid1") ? v.vcn_id : var.network_dependency.vcns[v.vcn_id].id
    network_security_groups = {
      (k) = {
          compartment_id = startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id
          display_name = "${lower(v.display_name)}-nsg"
          ingress_rules = {
            "INGRESS-TO-PORT-2484-RULE" = {
                description  = "Allows ingress connectivity to TCP port 2484."
                stateless    = false
                protocol     = "TCP"
                src          = data.oci_core_vcn.these[k].cidr_block
                src_type     = "CIDR_BLOCK"
                dst_port_min = 2484
                dst_port_max = 2484
            }
            "INGRESS-TO-PORT-8005-RULE" = {
                description  = "Allows ingress connectivity to TCP port 8005."
                stateless    = false
                protocol     = "TCP"
                src          = data.oci_core_vcn.these[k].cidr_block
                src_type     = "CIDR_BLOCK"
                dst_port_min = 8005
                dst_port_max = 8005
            }
          }
      }
    }
  } if v.enable_default_nsg == true }

  network_configuration = {
    network_configuration_categories = {
      "AUTONOMOUS-RECOVERY-SERVICE-NSGS" = {
        inject_into_existing_vcns = local.inject_into_existing_vcns
      }
    }
  }  
}

data "oci_core_vcn" "these" {
  for_each = var.autonomous_recovery_service_configuration.recovery_subnets
    vcn_id = startswith(each.value.vcn_id, "ocid1") ? each.value.vcn_id : var.network_dependency.vcns[each.value.vcn_id].id
}

module "autonomous_recovery_service_nsg" {
  source                = "github.com/oci-landing-zones/terraform-oci-modules-networking?ref=v0.8.2"
  network_configuration = local.network_configuration
  tenancy_ocid          = var.tenancy_ocid
}
