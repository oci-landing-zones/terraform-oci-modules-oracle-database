locals {
  policies_configuration = {
    supplied_policies = {for k, v in var.autonomous_recovery_service_configuration.recovery_subnets : "${k}-IAM-POLICY" => {
      name = "${v.display_name}-iam-policy"
      description = "Autonomous Recovery Service policy for ${v.display_name}"
      compartment_id = startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id
      statements = [
        "Allow service database to manage recovery-service-family in compartment id ${startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id}",
        "Allow service database to manage tagnamespace in compartment id ${startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id}",
        "Allow service rcs to manage recovery-service-family in compartment id ${startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id}",
        "Allow service rcs to manage virtual-network-family in compartment id ${startswith(coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id), "ocid1") ? coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id) : var.compartments_dependency[coalesce(v.compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id)].id}",
      ]
    } if v.enable_iam_policies == true }
  }
}

module "autonomous_recovery_service_policies" {
  source                 = "github.com/oracle-quickstart/terraform-oci-cis-landing-zone-iam//policies?ref=v0.3.4"
  tenancy_ocid           = var.tenancy_ocid
  policies_configuration = local.policies_configuration
  providers              = { oci = oci.home }
}
