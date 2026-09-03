<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_oci"></a> [oci](#provider\_oci) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_dynamic_groups"></a> [dynamic\_groups](#module\_dynamic\_groups) | github.com/oci-landing-zones/terraform-oci-modules-iam//dynamic-groups | v0.3.0 |
| <a name="module_master_keys"></a> [master\_keys](#module\_master\_keys) | github.com/oci-landing-zones/terraform-oci-modules-security//vaults | v0.2.3 |
| <a name="module_policies"></a> [policies](#module\_policies) | github.com/oci-landing-zones/terraform-oci-modules-iam//policies | v0.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [null_resource.wait](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [oci_database_autonomous_database.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_autonomous_database) | resource |
| [oci_kms_key.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/kms_key) | data source |
| [oci_kms_vault.these](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/kms_vault) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_autonomous_databases_configuration"></a> [autonomous\_databases\_configuration](#input\_autonomous\_databases\_configuration) | Configuration object for multiple Autonomous Databases with default values and overrides. | <pre>object({<br/>    default_compartment_id = optional(string)<br/>    default_defined_tags   = optional(map(string), {})<br/>    default_freeform_tags  = optional(map(string), {})<br/><br/>    databases = map(object({<br/>      compartment_id              = optional(string)<br/>      display_name                = optional(string)<br/>      db_name                     = string<br/>      db_workload                 = optional(string, "OLTP") # OLTP, DW, AJD, APEX, for Dedicated, only OLTP and DW are allowed<br/>      db_version                  = optional(string, "26ai") # only supported for ADB-Serverless. For ADB-D, the db_version is determined by the container database.<br/>      db_edition                  = optional(string)         # ENTERPRISE_EDITION, STANDARD_EDITION<br/>      is_dedicated                = optional(bool, true)     # Deploying on Dedicated Exadata Infrastructure? If selected, db_workload can only be DW OLTP<br/>      autonomous_container_db_id  = optional(string)         # Only for ADB-D<br/>      is_free_tier                = optional(bool, false)<br/>      is_dev_tier                 = optional(bool, false)<br/>      license_model               = optional(string, "LICENSE_INCLUDED") # default LICENSE_INCLUDED, BRING_YOUR_OWN_LICENSE, must be null for Dedicated<br/>      enable_cpu_auto_scaling     = optional(bool, true)<br/>      enable_storage_auto_scaling = optional(bool, false) # Only for serverless, not applicable for dedicated.<br/>      ecpu_count                  = optional(number, 2)   # 2 is the minimum count for ECPUs. For the same performance of 1 OCPU, the recommended ECPU count is 4. <br/>      dw_storage_size_in_tbs      = optional(number, 1)   # It is required for "DW" db_workload. Unit is terabytes.<br/>      non_dw_storage_size_in_gbs  = optional(number, 32)  # Use this for all db_workloads, except "DW". Unit is gigabytes (minimum is 20GB). For "DW" use dw_storage_size_in_tbs.<br/>      admin_password              = string<br/>      character_set               = optional(string) # Default is "AL32UTF8"<br/>      national_character_set      = optional(string) # Default is "AL16UTF16"<br/>      backup_retention_in_days    = optional(number) # Retention period, in days, for long-term backups. For ADB-D, this is determined by the value set at Autonomous Container Database<br/>      networking = optional(object({<br/>        whitelisted_ips                       = optional(list(string), []) # does not apply when private endpoint is enabled.<br/>        enable_private_endpoint               = optional(bool, false)<br/>        allow_public_access_without_whitelist = optional(bool, false)<br/>        private_endpoint_ip                   = optional(string)<br/>        subnet_id                             = optional(string)<br/>        network_security_groups               = optional(list(string), []) # Only applicable for Serverless, not applicable for Dedicated.<br/>      }))<br/>      security = optional(object({<br/>        # for ADB-D, tde configuration is inheritated from the autonomous container database<br/>        tde = optional(object({<br/>          deploy_iam_policy_and_dyn_group_for_encryption_key = optional(bool, true)<br/>          existing_oci_vault_id                              = string<br/>          deploy_new_oci_encryption_key                      = optional(bool, true)<br/>          existing_oci_encryption_key_id                     = optional(string) # Required when deploy_new_oci_encryption_key is false and deploy_iam_policy_and_dyn_group_for_encryption_key is true.<br/>        }))<br/>        zpr_attributes = optional(list(object({ # it only applies if networking.enable_private_endpoint is true.<br/>          namespace  = optional(string, "oracle-zpr")<br/>          attr_name  = string<br/>          attr_value = string<br/>          mode       = optional(string, "enforce")<br/>        })))<br/>      }))<br/>      defined_tags  = optional(map(string))<br/>      freeform_tags = optional(map(string))<br/>    }))<br/><br/>  })</pre> | n/a | yes |
| <a name="input_compartments_dependency"></a> [compartments\_dependency](#input\_compartments\_dependency) | A map of objects containing the externally managed compartments this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the compartment OCID) of string type. | <pre>map(object({<br/>    id = string # the compartment OCID<br/>  }))</pre> | `null` | no |
| <a name="input_databases_dependency"></a> [databases\_dependency](#input\_databases\_dependency) | A map of objects containing the externally managed database resources this module may depend on. Supported resources are 'container\_databases', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with container database OCID. | <pre>object({<br/>    container_databases = optional(map(object({<br/>      id = string<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_enable_output"></a> [enable\_output](#input\_enable\_output) | Whether Terraform should enable the module output. | `bool` | `true` | no |
| <a name="input_kms_dependency"></a> [kms\_dependency](#input\_kms\_dependency) | A map of objects containing the externally managed encryption keys this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the key OCID) of string type. | <pre>map(object({<br/>    id = string # the key OCID.<br/>  }))</pre> | `null` | no |
| <a name="input_module_name"></a> [module\_name](#input\_module\_name) | The module name. | `string` | `"autonomous_database"` | no |
| <a name="input_network_dependency"></a> [network\_dependency](#input\_network\_dependency) | An object containing the externally managed network resources this module may depend on. Supported resources are 'subnets', and 'network\_security\_groups', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with the subnet or NSG OCID. | <pre>object({<br/>    subnets = optional(map(object({<br/>      id = string # the subnet OCID<br/>    })))<br/>    network_security_groups = optional(map(object({<br/>      id = string # the NSG OCID<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_tenancy_ocid"></a> [tenancy\_ocid](#input\_tenancy\_ocid) | The OCID of the tenancy where the Autonomous Database is created. | `string` | n/a | yes |
| <a name="input_vaults_dependency"></a> [vaults\_dependency](#input\_vaults\_dependency) | A map of objects containing the externally managed vaults this module may depend on. All map objects must have the same type and must contain at least an 'id' attribute (representing the vault OCID) of string type. | <pre>map(object({<br/>    id = string # the vault OCID.<br/>  }))</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_autonomous_database_resources"></a> [autonomous\_database\_resources](#output\_autonomous\_database\_resources) | Alias for autonomous_databases_resources for integrations that read the singular Autonomous Database output name. |
| <a name="output_autonomous_databases"></a> [autonomous\_databases](#output\_autonomous\_databases) | The Autonomous Databases |
| <a name="output_autonomous_databases_dependency"></a> [autonomous\_databases\_dependency](#output\_autonomous\_databases\_dependency) | Alias for Orchestrator Autonomous Databases dependency consumption. |
| <a name="output_autonomous_databases_resources"></a> [autonomous\_databases\_resources](#output\_autonomous\_databases\_resources) | Minimal Autonomous Databases resources map for downstream dependency consumption. |
<!-- END_TF_DOCS -->
