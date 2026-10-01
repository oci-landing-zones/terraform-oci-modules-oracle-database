# OCI Landing Zones Base Database Service Module

![Landing Zone logo](../landing_zone_300.png)

This module manages Base Database Service DB Systems and related resources in Oracle Cloud Infrastructure (OCI). Base Database Service provides single-node DB Systems on virtual machines.

The module supports bringing in external dependencies that managed resources depend on, including compartments, subnets, network security groups, secrets, and encryption keys.
This module does not deploy VCNs, subnets, network security groups, Vaults, encryption keys, or secrets. It creates one Database Home and one database for each DB System.

Check [module specification](./SPEC.md) for a full description of module requirements, supported variables, managed resources, and outputs.

Check the [examples](./examples/) folder for actual module usage.

- [Features](#features)
- [Requirements](#requirements)
- [How to Invoke the Module](#invoke)
- [Module Functioning](#functioning)
  - [DB Systems](#db-systems)
  - [External Dependencies](#ext-dep)
- [Outputs](#outputs)
- [Related Documentation](#related)
- [Known Issues](#issues)

## <a name="features">Features</a>

The following features are currently supported by the module:

- Single-node Base Database Service DB Systems.
- Inline Database Home, database, and initial PDB configuration.
- Additional PDBs managed as separate resources.
- Network access using client subnets and network security groups.
- Transparent data encryption using customer-managed OCI Vault keys.
- Automatic backup and backup destination configuration.
- Bring Your Own License and License Included deployment models.
- Support for external dependencies for compartments, subnets, network security groups, secrets, encryption keys, and Recovery Service policies.

## <a name="requirements">Requirements</a>

### Terraform version >= 1.3.0

This module requires Terraform binary version 1.3.0 or greater because it uses Optional Object Type Attributes.

### IAM permissions

This module requires the following IAM permissions:

```
Allow group <GROUP-NAME> to manage database-family in compartment <DB-SYSTEM-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use subnets in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use network-security-groups in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use keys in compartment <KMS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use key-delegate in compartment <KMS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to read secret-bundles in compartment <SECRETS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to inspect compartments in tenancy
```

The network security group permission is required only when NSGs are configured. The key permissions are required only when a customer-managed key is configured. The secret-bundle permission is required only when an administrator password or additional PDB password uses `*_password_secret_id`.

## <a name="invoke">How to Invoke the Module</a>

Terraform modules can be invoked locally or remotely.

For local use, set `source` to the module path:

```hcl
module "base_database" {
  source = "../.."

  db_systems_configuration = var.db_systems_configuration
  tenancy_ocid             = var.tenancy_ocid
}
```

For remote use, refer to this module directory in the repository:

```hcl
module "base_database" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-exadata//base-database?ref=v1.4.0"

  db_systems_configuration = var.db_systems_configuration
  tenancy_ocid             = var.tenancy_ocid
}
```

## <a name="functioning">Module Functioning</a>

The module defines a top-level variable used to manage Base Database Service DB Systems:

- **db_systems_configuration**: for managing DB Systems and related resources.

### <a name="db-systems">DB Systems</a>

DB Systems are managed using the **db_systems_configuration** object. It contains a set of attributes starting with the prefix **default_** and one attribute named **db_systems**. The **default_** attribute values are applied to all DB Systems within **db_systems**, unless overridden at the DB System level.

The *default_* attributes are the following:

- **default_compartment_id**: Default compartment for all DB Systems. It can be a literal OCID or a key in *compartments_dependency*. See [External Dependencies](#ext-dep).
- **default_subnet_id**: Default client subnet for all DB Systems. It can be a literal OCID or a key in *network_dependency.subnets*. See [External Dependencies](#ext-dep).
- **default_defined_tags**: Optional default defined tags for all DB Systems.
- **default_freeform_tags**: Optional default freeform tags for all DB Systems.

The DB Systems are defined within the **db_systems** attribute. In Terraform terms, it is a map of objects, where each object is referred to by an identifying key.

Supported DB System attributes include:

- **display_name**: The DB System display name.
- **ssh_public_keys**: Public SSH keys for DB System access.
- **compartment_id**: Optional DB System compartment. *default_compartment_id* is used if undefined. It can be a literal OCID or a key in *compartments_dependency*.
- **subnet_id**: Optional client subnet. *default_subnet_id* is used if undefined. It can be a literal OCID or a key in *network_dependency.subnets*.
- **nsg_ids**: Optional network security groups. Values can be literal OCIDs or keys in *network_dependency.network_security_groups*.
- **hostname**: Optional hostname. If omitted, it is derived from *display_name*.
- **placement**: Optional availability-domain and fault-domain indexes. The module looks up Availability Domains in the tenancy. The default is Availability Domain `1` and fault domain `[1]`. Because the module creates single-node DB Systems, exactly one fault domain must be selected.
- **kms_key_id**: Optional customer-managed encryption key. It can be a literal OCID or a key in *kms_dependency*.
- **kms_key_version_id**: Optional customer-managed key-version OCID.
- **db_system_options**: Optional DB System options, including *storage_management*.
- **shape**: Optional DB System shape. The default is `VM.Standard.E5.Flex`.
- **cpu_core_count**: Optional CPU core count. The default is `1`.
- **database_edition**: Optional database edition. The default is `ENTERPRISE_EDITION`.
- **license_model**: Optional license model. The default is `BRING_YOUR_OWN_LICENSE`.
- **data_storage_size_in_gb**: Optional data storage size. The default is `256` GB.
- **storage_volume_performance_mode**: Optional storage performance mode. The default is `HIGH_PERFORMANCE`.
- **time_zone**: Optional DB System time zone. The default is `UTC`.
- **defined_tags**: Optional DB System defined tags.
- **freeform_tags**: Optional DB System freeform tags.

The module creates one single-node DB System for each entry. Each DB System creates one Database Home and one database.

The **db_home** object configures the Database Home and its database. Supported Database Home attributes include **display_name**, **database_software_image_id**, and **is_unified_auditing_enabled**.

Supported database attributes include:

- **db_name**: The database name.
- **db_version**: The database version.
- **admin_password**: Literal database administrator password.
- **admin_password_secret_id**: OCI Vault secret OCID or *secrets_dependency* key containing the administrator password.
- **database_software_image_id**: Optional database software image OCID.
- **character_set**: Database character set. The default is `AL32UTF8`.
- **ncharacter_set**: National character set. The default is `AL16UTF16`.
- **db_workload**: Optional legacy database workload input. The default is `null` because OCI deprecated this field for Base Database Service.
- **pdb_name**: Optional initial PDB name.
- **backup_id**: Optional backup OCID used for restore operations.
- **backup_tde_password**: Optional sensitive backup TDE password.
- **tde_wallet_password**: Optional sensitive TDE wallet password.
- **time_stamp_for_point_in_time_recovery**: Optional point-in-time recovery timestamp.
- **additional_pdbs**: Optional map of additional PDB definitions.
- **db_backup_config**: Optional automatic backup configuration.

Define exactly one of **admin_password** or **admin_password_secret_id** for each database. An empty literal is treated as absent. The module retrieves secret content when a secret reference is used and marks the resolved password as sensitive. Terraform stores the resolved value in state. Treat the state as sensitive data and protect it with an encrypted backend and appropriately restricted access.

Additional PDBs are defined within **additional_pdbs**:

```hcl
additional_pdbs = {
  reporting = {
    pdb_name                     = "REPORTING"
    pdb_admin_password_secret_id = "REPORTING-PDB-PASSWORD"
    freeform_tags                = { workload = "reporting" }
  }
}
```

Each additional PDB must define exactly one of **pdb_admin_password** or **pdb_admin_password_secret_id**. The PDB name must be unique and must differ from the database name and initial PDB name.

Backup configuration is defined within **db_backup_config**. Supported attributes include **auto_backup_enabled**, backup windows, full-backup scheduling, **backup_deletion_policy**, **recovery_window_in_days**, **run_immediate_full_backup**, and **backup_destination_details**.

Supported backup destination types are `AWS_S3`, `DBRS`, `LOCAL`, `NFS`, `OBJECT_STORE`, and `RECOVERY_APPLIANCE`. A `DBRS` destination requires **dbrs_policy_id**. The policy can be a direct OCID, a key in **recovery_service_dependency**, or an Oracle-managed policy key such as `bronze`, `silver`, `gold`, or `platinum` when tenancy lookup is enabled.

### <a name="ext-dep">External Dependencies</a>

An optional feature, external dependencies are resources managed elsewhere that resources managed by this module may depend on. The following dependencies are supported:

- **compartments_dependency**: A map of objects containing externally managed compartments. Each object contains an *id* attribute with the compartment OCID.

```hcl
compartments_dependency = {
  DATABASE-CMP = {
    id = "ocid1.compartment.oc1..example"
  }
}
```

- **network_dependency**: An object containing externally managed subnets and network security groups. Each object contains an *id* attribute with the relevant OCID.

```hcl
network_dependency = {
  subnets = {
    DATABASE-SUBNET = {
      id = "ocid1.subnet.oc1.eu-frankfurt-1.example"
    }
  }
  network_security_groups = {
    DATABASE-NSG = {
      id = "ocid1.networksecuritygroup.oc1.eu-frankfurt-1.example"
    }
  }
}
```

- **secrets_dependency**: A map of externally managed OCI Vault secrets. Use a map key as **admin_password_secret_id** or **pdb_admin_password_secret_id** to avoid placing the literal OCID in each database configuration.

```hcl
secrets_dependency = {
  DB-PASSWORD = {
    id = "ocid1.vaultsecret.oc1.eu-frankfurt-1.example"
  }
}
```

- **kms_dependency**: A map of externally managed encryption keys. Use a map key as **kms_key_id**.

```hcl
kms_dependency = {
  DATABASE-KEY = {
    id = "ocid1.key.oc1.eu-frankfurt-1.example"
  }
}
```

- **recovery_service_dependency**: Externally managed Recovery Service protection policies. Use a map key as **dbrs_policy_id** when the backup destination type is `DBRS`.

```hcl
recovery_service_dependency = {
  protection_policies = {
    custom_policy = {
      id = "ocid1.recoveryservicepolicy..."
    }
  }
}
```

Use the dependency key in the DBRS backup configuration:

```hcl
dbrs_policy_id = "custom_policy"
```

## Outputs

The module publishes the following outputs:

- **db_systems**: Curated details for the deployed Base Database Service DB Systems.
- **additional_pdbs**: Curated details for additional Pluggable Databases managed by the module.
- **db_system_resources**: A minimal DB System resource map for downstream dependency consumption.
- **db_system_dependency**: An alias exposing the DB System dependency map for downstream modules such as `common-database`.

The dependency output contains the following shape:

```hcl
{
  "<db-system-key>" = {
    id             = "ocid1.dbsystem.oc1..."
    compartment_id = "ocid1.compartment.oc1..."
  }
}
```

## <a name="related">Related Documentation</a>

- [Oracle Base Database Service](https://docs.oracle.com/en/cloud/paas/base-database/)
- [About Base Database Service DB Systems](https://docs.oracle.com/en/cloud/paas/base-database/about-dbs/)
- [VCN and Subnets for Base Database Service](https://docs.oracle.com/en/cloud/paas/base-database/vcn-subnets/)
- [Base Database Service example](./examples/base-database-simple/)

## <a name="issues">Known Issues</a>

- The module manages single-node DB Systems only.
- OCI provider behavior can require staged backup-destination changes when switching between DBRS and Object Storage.
