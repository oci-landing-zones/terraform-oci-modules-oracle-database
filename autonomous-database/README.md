# OCI Landing Zones Autonomous Database Module

![Landing Zone logo](../landing_zone_300.png)

This module manages Autonomous Databases and related resources in Oracle Cloud Infrastructure (OCI). Autonomous Database is a fully-managed, secure, and highly available database service that automates database management, tuning, and security.

The module supports bringing in external dependencies that managed resources depend on, including compartments, subnets, network security groups, secrets, vaults and encryption keys.
This module does not deploy Autonomous VM Clusters or Autonomous Container Databases. It deploys Autonomous Databases on shared/serverless infrastructure or inside an existing Autonomous Container Database.

Check [module specification](./SPEC.md) for a full description of module requirements, supported variables, managed resources and outputs.

Check the [examples](./examples/) folder for actual module usage.

- [Features](#features)
- [Requirements](#requirements)
- [How to Invoke the Module](#invoke)
- [Module Functioning](#functioning)
  - [Autonomous Databases](#adb)
  - [External Dependencies](#ext-dep)
- [Outputs](#outputs)
- [Related Documentation](#related)
- [Known Issues](#issues)

## <a name="features">Features</a>
The following features are currently supported by the module:

- Autonomous Databases.
- Network access control using private endpoints and whitelisted IPs.
- Transparent data encryption using customer-managed keys.
- Integration with IAM policies and dynamic groups
- Support for external dependencies (compartments, subnets, network security groups, secrets, vaults and keys)

## <a name="requirements">Requirements</a>
### Terraform version >= 1.3.0

This module requires Terraform binary version 1.3.0 or greater, as it relies on Optional Object Type Attributes feature.

### IAM permissions

This module requires the following IAM permissions:

```
Allow group <GROUP-NAME> to manage autonomous-database-family in compartment <ADB-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use subnets in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use network-security-groups in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use keys in compartment <KMS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to read secret-bundles in compartment <SECRETS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to manage dynamic-groups in tenancy
Allow group <GROUP-NAME> to manage policies in tenancy
```

The secret-bundle permission is required only when an Autonomous Database sets **admin_password_secret_id**.

Note: When deploying ADB Dedicated, TDE is inherited from the existing Autonomous Container Database. If that container database is managed by an existing Core LZ, review the container database key policy outside this module. In \<service_label\>-top-cmp, edit \<service_label\>-database-dynamic-group-policy, change
```
allow dynamic-group <service_label>-database-kms-dynamic-group to use keys in compartment <service_label>-database-cmp
```
to
```
allow dynamic-group <service_label>-database-kms-dynamic-group to manage keys in compartment <service_label>-database-cmp
```


## <a name="invoke">How to Invoke the Module</a>

Terraform modules can be invoked locally or remotely.

For local use, set `source` to the module path:

```hcl
module "autonomous_database" {
  source = "../.."
  autonomous_databases_configuration = var.autonomous_databases_configuration
  secrets_dependency                 = var.secrets_dependency
  tenancy_ocid                       = var.tenancy_ocid
  providers = {
    oci      = oci
    oci.home = oci.home
  }
}
```

For remote use, refer to this module directory in the repository:

```hcl
module "autonomous_database" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-oracle-database//autonomous-database?ref=v1.3.1"
  autonomous_databases_configuration = var.autonomous_databases_configuration
  secrets_dependency                 = var.secrets_dependency
  tenancy_ocid                       = var.tenancy_ocid
  providers = {
    oci      = oci
    oci.home = oci.home
  }
}
```

## <a name="functioning">Module Functioning</a>

The module defines a top-level variable used to manage Autonomous Databases:
- **autonomous_databases_configuration**: for managing Autonomous Databases and related resources.

### <a name="adb">Autonomous Databases</a>

Autonomous Databases are managed using the **autonomous_databases_configuration** object. It contains a set of attributes starting with the prefix **default_** and one attribute named **databases**. The **default_** attribute values are applied to all databases within **databases**, unless overridden at the database level.

The *default_* attributes are the following:
- **default_compartment_id**: Default compartment for all databases. Can be overridden by *compartment_id* in each database. This attribute is overloaded and can be assigned either a literal OCID or a reference (a key) to an OCID in *compartments_dependency* variable. See [External Dependencies](#ext-dep).
- **default_defined_tags**: (Optional) Default defined tags for all databases. Can be overridden by *defined_tags* in each database.
- **default_freeform_tags**: (Optional) Default freeform tags for all databases. Can be overridden by *freeform_tags* in each database.

The databases themselves are defined within the **databases** attribute. In Terraform terms, it is a map of objects, where each object is referred by an identifying key. Supported attributes include:
- **compartment_id**: (Optional) The database compartment. *default_compartment_id* is used if undefined.
- **display_name**: (Optional) The database display name. It defaults to *db_name* if undefined.
- **db_name**: The database name.
- **db_workload**: (Optional) The workload type ("OLTP", "DW", "AJD", "APEX"). Default is "OLTP".
- **db_version**: (Optional) The Serverless database version defaults to `26ai`. Dedicated databases use the version of their Autonomous Container Database.
- **db_edition**: (Optional) The database edition ("ENTERPRISE_EDITION","STANDARD_EDITION").
- **is_dedicated**: (Optional) Indicates whether the database is provisioned on a Dedicated Exadata Infrastructure. Set to false for Autonomous Database Shared/Serverless. Default is true.
- **autonomous_container_db_id**: (Optional) The Autonomous Container Database in which to provision this Autonomous Database. Only applicable and required when *is_dedicated* is true. This attribute is overloaded and can be assigned either a literal OCID or a reference (a key) to an OCID in *databases_dependency* variable. The OCI Landing Zones Orchestrator integration expects a literal Autonomous Container Database OCID in this release.
- **ecpu_count**: (Optional) The number of eCPU cores. Default is 2.
- **dw_storage_size_in_tbs**: (Optional) The storage size in Terabytes for workloads of type "DW". Default is 1.
- **non_dw_storage_size_in_gbs**: (Optional) The storage size in Gigabytes for workloads other than "DW". Default is 32. For "DW" workloads, use *dw_storage_size_in_tbs*.
- **admin_password**: (Optional) Literal database administrator password. The module marks the value as sensitive.
- **admin_password_secret_id**: (Optional) OCI Vault secret OCID or *secrets_dependency* key containing the database administrator password. Store the password as nonempty UTF-8 text in the secret. The module reads the `CURRENT` version, decodes the Base64 payload returned by OCI, and marks the password as sensitive.

Define exactly one of **admin_password** or **admin_password_secret_id** for each Autonomous Database. An empty literal is treated as absent.

Prefer **admin_password_secret_id** to avoid committing a literal password to Git and to centralize password rotation and audit activity in OCI Vault. Regardless of the source, Terraform retrieves the password and stores it in the Terraform state file. Treat the state as sensitive data and protect it with an encrypted backend and appropriately restricted access.

- **is_free_tier**: (Optional) Indicates whether the database is an Always Free resource. Default is false.
- **is_dev_tier**: (Optional) Indicates whether the database is for developer to build and test applications. Developer databases come with limited resources and is not intended for large-scale testing and production deployments. Default is false.
- **license_model**: (Optional) For Serverless, choose `LICENSE_INCLUDED` (default) or `BRING_YOUR_OWN_LICENSE`. The module omits this setting for Dedicated databases.
- **enable_cpu_auto_scaling**: (Optional) Whether CPU auto scaling is enabled. Default is true.
- **enable_storage_auto_scaling**: (Optional) Whether storage auto scaling is enabled. Default is false. Only applicable for serverless, not applicable for dedicated.
- **character_set**: (Optional) The database character set. Default is "AL32UTF8". 
- **national_character_set**: (Optional) The database character set. Default is "AL16UTF16". 
- **backup_retention_in_days**: (Optional) Retention period, in days, for long-term backups. For ADB-D, this is determined by the value set at Autonomous Container Database
- **networking**: (Optional) The database networking settings. It contains the following attributes:
    - **whitelisted_ips**: (Optional) The List of IP addresses allowed to access the database. It does not apply when private endpoint is enabled. Default is an empty list([]).
    - **enable_private_endpoint** (Optional) Whether a private endpoint is enabled for the database. When this is true, the database is assigned a private IP address from the subnet provided in *subnet_id*, and the attribute *whitelisted_ips* is ignored. For databases enabled with private endpoint, the network access control is provided by security rules in Network Security Groups (NSGs) or security lists. Default is false.
    - **private_endpoint_ip** (Optional): The private IP address for the database private endpoint. It must be a single IP within the CIDR range of the subnet provided in *subnet_id*. If undefined, a random IP address is chosen from the subnet range. Set this value when creating the database; OCI does not reliably apply later changes to the private endpoint IP of an existing Autonomous Database. Only applicable when *enable_private_endpoint* is true.
    - **subnet_id**: (Optional) The subnet for the database. Only applicable when *enable_private_endpoint* is true. This attribute is overloaded and can be assigned either a literal OCID or a reference (a key) to an OCID in *network_dependency* variable.
    - **network_security_groups**: (Optional) List of NSGs for the database. Only applicable when *enable_private_endpoint* is true. This attribute is overloaded and can be assigned either a literal OCID or a reference (a key) to an OCID in *network_dependency* variable. Only applicable for Serverless, not applicable for Dedicated.
- **security**: (Optional) The database security settings. Only applicable for Serverless, not applicable for Dedicated. When using ADB-D, this is determined by the Autonomous Container Database.
    - **tde**: (Optional) Transparent Data Encryption settings. 
      - **deploy_iam_policy_and_dyn_group_for_encryption_key**: (Optional) When `security.tde` is configured for Serverless, this defaults to `true`. The module creates a dynamic group whose membership rule matches resource principals in the database compartment and a policy granting that group access to the configured Vault and key. Set the flag to `false` when existing IAM rules already grant the required access.
      - **existing_oci_vault_id**(Optional): The OCI vault holding the encryption key. Required if defining tde. This attribute is overloaded and can be assigned either a literal OCID or a reference (a key) to an OCID in *vaults_dependency* variable. For 1.1.0 upgrade compatibility only, vault OCIDs stored in *kms_dependency* are accepted as a deprecated fallback when no *vaults_dependency* match exists.
      - **deploy_new_oci_encryption_key**: (Optional) Whether to deploy a new encryption key in the referenced Vault. Default value is *true*. The Vault OCID can remain unknown until apply when the ADB configuration keys and the key deployment flag are known during planning. For an existing module-managed key, use a `vaults_dependency` entry with the current Vault OCID and management endpoint as described below.
      - **existing_oci_encryption_key_id**: (Optional) The existing encryption key id. Required when *deploy_new_oci_encryption_key* is *false* and *deploy_iam_policy_and_dyn_group_for_encryption_key* is *true*. When using an existing key, Vault and key OCIDs can remain unknown until apply.
    - **zpr_attributes**: (Optional) List of objects representing ZPR attributes. Only applicable when *enable_private_endpoint* is true.
        - **namespace**: (Optional) ZPR namespace. Default is *oracle-zpr*, a default namespace created by Oracle and available in all tenancies.
        - **attr_name**: (Optional) ZPR attribute name. It must exist in the specified namespace.
        - **attr_value**: (Optional) ZPR attribute value.
        - **mode** &ndash; (Optional) ZPR mode. Default value is *enforce*.    
- **defined_tags**: (Optional) Database defined tags.
- **freeform_tags**: (Optional) Database freeform tags.

### <a name="ext-dep">External Dependencies</a>
Use the following inputs to reference existing resources. Replace values in angle brackets with the OCIDs or endpoint from your tenancy.
- **compartments_dependency**: A map of objects containing externally managed compartments. All map objects must have the same type and must contain at least an *id* attribute with the compartment OCID.

Example:
```json
{
  "DATABASE-CMP": {
    "id": "<compartment-ocid>"
  }
}
```
- **network_dependency**: An object containing externally managed network resources (subnets, network security groups). All map objects within each resource title must have the same type and should contain the following attributes:
  - An *id* attribute with the subnet OCID.
  - An *id* attribute with the network security group OCID.

Example:
```json
{
  "subnets": {
    "DATABASE-SUBNET": {
      "id": "<subnet-ocid>"
    }
  },
  "network_security_groups": {
    "DATABASE-NSG": {
      "id": "<network-security-group-ocid>"
    }
  }
}
```

- **secrets_dependency**: A map of externally managed OCI Vault secrets. Each object must contain an *id* attribute with the secret OCID. Use a map key as *admin_password_secret_id* to avoid placing the literal OCID in each database configuration.

Example:
```hcl
secrets_dependency = {
  "ADB-PASSWORD" = {
    id = "<vault-secret-ocid>"
  }
}
```

- **vaults_dependency**: A map of objects containing externally managed vaults. Each object requires an *id* attribute with the Vault OCID and accepts an optional *management_endpoint*. Use the map key as *security.tde.existing_oci_vault_id*. For an existing module-managed TDE key, supplying the current Vault management endpoint as a value known during planning prevents replacement caused by a deferred Vault lookup. Terraform checks that the endpoint matches the Vault when it reads the Vault, which can be during plan or apply. The legacy 1.1.0 pattern of storing vault OCIDs in *kms_dependency* is deprecated and kept only as a temporary upgrade fallback.

When a module-level `depends_on` has pending changes, as in the Orchestrator, Terraform can defer the Vault lookup until apply. A direct Vault OCID or a dependency entry with an endpoint unknown during planning can still lead to replacement of an existing key. Before applying an upgrade, check that the plan has no `oci_kms_key` deletion or replacement. If it does, use the same Vault OCID and its management endpoint from OCI in a `vaults_dependency` entry and re-plan. Destroying a key schedules its deletion and makes data encrypted with it inaccessible. [OCI Vault documentation](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/managingkeys_topic-To_delete_a_key.htm)

Example:
```json
{
  "DATABASE-VAULT": {
    "id": "<vault-ocid>",
    "management_endpoint": "<vault-management-endpoint>"
  }
}
```
- **kms_dependency**: A map of objects containing externally managed encryption keys. All map objects must have the same type and must contain at least an *id* attribute with the encryption key OCID.

Example:
```json
{
  "DATABASE-KEY": {
    "id": "<encryption-key-ocid>"
  }
}
```
- **databases_dependency**: An object containing the externally managed database resources this module may depend on. Supported resources are 'container_databases', represented as map of objects. Each object, when defined, must have an 'id' attribute of string type set with container database OCID.

Example:
```json
{
  "container_databases": {
    "CDB1": {
      "id": "<autonomous-container-database-ocid>"
    }
  }
}
```

## Outputs

Use `autonomous_databases_resources` to pass database details to another Terraform stack. The map uses the database keys from your configuration. For example:

```json
{
  "autonomous_databases": {
    "<database-key>": {
      "id": "<autonomous-database-ocid>",
      "compartment_id": "<compartment-ocid>",
      "display_name": "<display-name>",
      "db_workload": "OLTP",
      "ecpu_count": 2
    }
  }
}
```

The outputs `autonomous_database_resources` and `autonomous_databases_dependency` return the same map. Existing callers using `autonomous_databases` can keep that output. It returns `ocid`, `display_name`, `db_workload`, and `ecpu_count` for each database.

When consumed through OCI Landing Zones Orchestrator or RMS Facade release 2.1.2, this map is persisted in the generated Autonomous Databases output file under the `autonomous_databases` top-level key.

## <a name="related">Related Documentation</a>
- [Autonomous Database](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adboverview.htm)

## <a name="issues">Known Issues</a>
A deferred Vault lookup can cause Terraform to propose replacing an existing managed TDE key. For the required Vault dependency and management endpoint, see [Upgrading to 1.3.1](../RELEASE-NOTES.md#upgrading-to-131).

For more details, refer to the [OCI Autonomous Database documentation](https://docs.oracle.com/en-us/iaas/Content/Database/Tasks/adbmanaging.htm).
