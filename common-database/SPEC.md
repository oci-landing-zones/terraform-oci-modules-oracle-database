# Common Database Module Specification

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| oracle/oci | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_database_db_home.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_db_home) | resource |
| [oci_database_database.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_database) | resource |
| [oci_database_pluggable_database.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_pluggable_database) | resource |

## Inputs

The module's complete structural types, defaults, and validations are defined in [`variables.tf`](./variables.tf). The public inputs are:

- `module_name`
- `enable_output`
- `database_dependency`
- `vm_cluster_dependency`
- `db_system_dependency`
- `kms_dependency`
- `recovery_service_dependency`
- `default_defined_tags`
- `default_freeform_tags`
- `cloud_db_homes_configuration`
- `databases_configuration`
- `pluggable_databases_configuration`

## Outputs

| Name | Description |
| ---- | ----------- |
| `database_homes` | Raw Database Home resources (sensitive). |
| `databases` | Raw container database resources (sensitive). |
| `pluggable_databases` | Raw PDB resources (sensitive). |
| `database_resources` | Minimal ID maps for dependency handoff. |
| `database_dependency` | Alias of `database_resources`. |
<!-- END_TF_DOCS -->
