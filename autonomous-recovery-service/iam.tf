locals {
  iam_policy_compartment_reference = trimspace(coalesce(var.autonomous_recovery_service_configuration.iam_policy_compartment_id, var.autonomous_recovery_service_configuration.default_compartment_id))
  iam_policy_compartment_id        = startswith(local.iam_policy_compartment_reference, "ocid1") ? local.iam_policy_compartment_reference : trimspace(var.compartments_dependency[local.iam_policy_compartment_reference].id)

  policies_configuration = {
    supplied_policies = var.autonomous_recovery_service_configuration.enable_iam_policy ? {
      "AUTONOMOUS-RECOVERY-SERVICE-IAM-POLICY" = {
        name           = "autonomous-recovery-service-iam-policy"
        description    = "Autonomous Recovery Service policy"
        compartment_id = local.iam_policy_compartment_id
        statements = [
          "Allow service database to manage recovery-service-family in compartment id ${local.iam_policy_compartment_id}",
          "Allow service database to manage tagnamespace in compartment id ${local.iam_policy_compartment_id}",
          "Allow service rcs to manage recovery-service-family in compartment id ${local.iam_policy_compartment_id}"
        ]
      }
    } : {}
  }
}

module "autonomous_recovery_service_policies" {
  source                 = "github.com/oracle-quickstart/terraform-oci-cis-landing-zone-iam//policies?ref=v0.3.4"
  tenancy_ocid           = trimspace(var.tenancy_ocid)
  policies_configuration = local.policies_configuration
  providers              = { oci = oci.home }
}
