<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_oci"></a> [oci](#provider_oci) | >= 8.25.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_database_db_system.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_db_system) | resource |
| [oci_database_pluggable_database.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_pluggable_database) | resource |
| [oci_identity_availability_domains.ads](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains) | data source |
| [oci_recovery_protection_policies.oracle_managed](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/recovery_protection_policies) | data source |
| [oci_secrets_secretbundle.admin_password](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/secrets_secretbundle) | data source |
| [oci_secrets_secretbundle.additional_pdb_admin_password](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/secrets_secretbundle) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tenancy_ocid"></a> [tenancy_ocid](#input_tenancy_ocid) | Tenancy OCID used to look up Availability Domains and Oracle-managed Recovery Service policies. | `string` | n/a | yes |
| <a name="input_db_systems_configuration"></a> [db_systems_configuration](#input_db_systems_configuration) | Configuration object for Base Database Service DB Systems, inline Database Homes, databases, and PDBs. | `object(...)` | `null` | no |
| <a name="input_compartments_dependency"></a> [compartments_dependency](#input_compartments_dependency) | Map of externally managed compartments indexed by dependency key. | `map(object({ id = string }))` | `null` | no |
| <a name="input_network_dependency"></a> [network_dependency](#input_network_dependency) | Externally managed subnets and network security groups. | `object(...)` | `null` | no |
| <a name="input_kms_dependency"></a> [kms_dependency](#input_kms_dependency) | Map of externally managed encryption keys indexed by dependency key. | `map(object({ id = string }))` | `null` | no |
| <a name="input_secrets_dependency"></a> [secrets_dependency](#input_secrets_dependency) | Map of OCI Vault secrets indexed by dependency key. | `map(object({ id = string }))` | `null` | no |
| <a name="input_recovery_service_dependency"></a> [recovery_service_dependency](#input_recovery_service_dependency) | Externally managed Recovery Service policies. | `any` | `null` | no |
| <a name="input_enable_output"></a> [enable_output](#input_enable_output) | Whether Terraform should enable module outputs. | `bool` | `true` | no |
| <a name="input_module_name"></a> [module_name](#input_module_name) | Module name used in the freeform module tag. | `string` | `"base_database"` | no |

The `db_systems_configuration` object contains default values and a `db_systems` map. Each DB System requires `display_name`, `ssh_public_keys`, and an inline `db_home.database` object containing `db_name` and `db_version`. Each DB System creates one single-node DB System, one Database Home, and one database. Additional PDBs are created as separate resources through `additional_pdbs`.

Compartment, subnet, NSG, KMS key, secret, and Recovery Service values can be supplied as direct OCIDs or dependency keys where supported. A DBRS backup destination requires `dbrs_policy_id` and `type = "DBRS"`.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_systems"></a> [db_systems](#output_db_systems) | Curated deployed Base Database Service DB System details. |
| <a name="output_additional_pdbs"></a> [additional_pdbs](#output_additional_pdbs) | Curated additional Pluggable Database details. |
| <a name="output_db_system_resources"></a> [db_system_resources](#output_db_system_resources) | Minimal DB System resource map for downstream dependency consumption. |
| <a name="output_db_system_dependency"></a> [db_system_dependency](#output_db_system_dependency) | DB System dependency map containing each DB System ID and compartment ID. |
<!-- END_TF_DOCS -->
