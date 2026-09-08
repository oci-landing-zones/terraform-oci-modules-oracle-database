# OCI Landing Zones Autonomous Recovery Service Module

![Landing Zone logo](../landing_zone_300.png)

This module manages Autonomous Recovery Service resources in Oracle Cloud Infrastructure (OCI): Recovery Service subnets, protection policies, and protected databases. It can also create NSGs and IAM policies for every configured resource.

The module accepts either literal OCIDs or keys that resolve through its external-dependency variables for compartments, networks, and databases.

Check the [examples](./examples/) folder for module usage.

- [Features](#features)
- [Requirements](#requirements)
- [How to Invoke the Module](#invoke)
- [Module Functioning](#functioning)
  - [IAM Policies](#iam-policies)
  - [Recovery Service Subnets](#recovery-subnets)
  - [Protection Policies](#protection-policies)
  - [Protected Databases](#protected-databases)
  - [External Dependencies](#external-dependencies)
  - [Outputs](#outputs)
- [Related Documentation](#related)
- [Known Issues](#issues)

## <a name="features">Features</a>

The module supports:

- Recovery Service subnets associated with one VCN and one or more subnets.
- Recovery Service protection policies.
- Protected database registration with one or more Recovery Service subnets.
- Protected-database passwords supplied as sensitive literals or retrieved from OCI Vault secrets.
- Optional generated NSGs that allow TCP ports 2484 and 8005 from the associated VCN CIDR.
- One optional module-level IAM policy, independent of configured resources.
- Default and per-resource defined and freeform tags.
- External compartment, VCN, subnet, NSG, and database dependencies.

## <a name="requirements">Requirements</a>

### Terraform version >= 1.5.0

This module requires Terraform 1.5.0 or later. The default *oci* provider manages Recovery Service resources and generated NSGs.

When root-level **enable_iam_policy** is *true*, the caller must also configure and pass the *oci.home* provider alias. IAM policies are created through that provider configuration.

### IAM permissions

The identity that applies this module needs permissions appropriate to the resources it manages. The following is a minimum starting point; scope each statement to the relevant compartments.

```
Allow group <GROUP-NAME> to manage recovery-service-family in compartment <RECOVERY-SERVICE-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use subnets in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to read vcns in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to manage network-security-groups in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to manage policies in compartment <RECOVERY-SERVICE-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to read secret-bundles in compartment <SECRETS-COMPARTMENT-NAME>
```

The policy-management permission is required only when **enable_iam_policy** is *true*. The NSG-management permission is required only when a recovery subnet sets **enable_default_nsg** to *true*. The secret-bundle permission is required only when a protected database sets **password_secret_id**.

## <a name="invoke">How to Invoke the Module</a>

Terraform modules can be invoked locally or remotely. Pass both provider configurations when enabling IAM policies.

For local use, set *source* to the module path:

```hcl
module "autonomous_recovery_service" {
  source = "../autonomous-recovery-service"

  tenancy_ocid = var.tenancy_ocid
  providers = {
    oci      = oci
    oci.home = oci.home
  }

  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
}
```

For remote use, refer to this module directory in the repository:

```hcl
module "autonomous_recovery_service" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-oracle-database//autonomous-recovery-service?ref=<VERSION>"

  tenancy_ocid = var.tenancy_ocid
  providers = {
    oci      = oci
    oci.home = oci.home
  }

  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
}
```

## <a name="functioning">Module Functioning</a>

The *autonomous_recovery_service_configuration* variable contains the following attributes. Map keys identify resources and can be used when one configured resource refers to another.

- **default_compartment_id** (Optional): Default compartment OCID or *compartments_dependency* key for recovery subnets, protection policies, and protected databases that omit **compartment_id**.
- **default_defined_tags** (Optional): Default defined tags for configured resources.
- **default_freeform_tags** (Optional): Default freeform tags for configured resources.
- **enable_iam_policy** (Optional): Creates the module-level IAM policy when set to *true*. Defaults to *false*.
- **iam_policy_compartment_id** (Optional): Compartment OCID or *compartments_dependency* key for the IAM policy. Falls back to **default_compartment_id** when omitted.
- **recovery_subnets** (Optional): Map of Recovery Service subnet definitions. Defaults to an empty map.
- **protection_policies** (Optional): Map of Recovery Service protection-policy definitions. Defaults to an empty map.
- **protected_databases** (Optional): Map of protected-database definitions. Defaults to an empty map.

```hcl
autonomous_recovery_service_configuration = {
  default_compartment_id    = "ocid1.compartment.oc1..example"
  iam_policy_compartment_id = "ocid1.compartment.oc1..example"
  enable_iam_policy         = true

  recovery_subnets = {
    RCV-SUBNET-1 = {
      display_name       = "rcv-subnet-1"
      vcn_id             = "ocid1.vcn.oc1..example"
      subnet_ids         = ["ocid1.subnet.oc1..example"]
      enable_default_nsg = true
    }
  }

  protection_policies = {
    POLICY-1 = {
      display_name                    = "rcv-protection-policy-1"
      backup_retention_period_in_days = 30
    }
  }

  protected_databases = {
    DATABASE-1 = {
      display_name         = "protected-database-1"
      password_secret_id   = "DATABASE-PASSWORD"
      database_unique_name = "DATABASE1"
      protection_policy_id = "POLICY-1"
      recovery_subnet_ids  = ["RCV-SUBNET-1"]
      database_id          = "ocid1.database.oc1..example"
      database_size        = 500
    }
  }
}
```

Leading and trailing whitespaces are removed from every string configuration value before the module uses it. This includes literal **password** values, but not password content retrieved from OCI Vault. **default_compartment_id** is used when a configured resource does not supply **compartment_id**. The module adds its module tag to every resource's freeform tags.

### <a name="iam-policies">IAM Policies</a>

**enable_iam_policy** (Optional): Creates one module-level IAM policy when set to *true*, regardless of whether recovery subnets, protection policies, or protected databases are configured. Defaults to *false*.

**iam_policy_compartment_id** (Optional): Compartment OCID or *compartments_dependency* key for the IAM policy. Falls back to **default_compartment_id** when omitted. At least one of these two attributes must be set when **enable_iam_policy** is *true*.

The policy grants the *database* and *rcs* services permission to manage *recovery-service-family* and grants the *database* service permission to manage *tagnamespace*.

IAM policy creation uses the *oci.home* provider alias. The caller must configure this alias and pass it to the module as shown in the invocation examples whenever **enable_iam_policy** is *true*.

### <a name="recovery-subnets">Recovery Service Subnets</a>

Each entry in **recovery_subnets** creates an *oci_recovery_recovery_service_subnet* resource with these attributes:

- **compartment_id** (Optional): Compartment OCID or *compartments_dependency* key. Falls back to *default_compartment_id*.
- **display_name** (Required): Display name for the Recovery Service subnet.
- **vcn_id** (Required): VCN OCID or *network_dependency.vcns* key.
- **subnet_ids** (Required): List of subnet OCIDs or *network_dependency.subnets* keys associated with the Recovery Service subnet.
- **nsg_ids** (Optional): List of NSG OCIDs or *network_dependency.network_security_groups* keys. Defaults to an empty list.
- **enable_default_nsg** (Optional): Creates and associates a module-managed NSG when set to *true* (default). *nsg_ids* is ignored. The generated NSG permits TCP 2484 and TCP 8005 from the associated VCN CIDR. When set to false, *nsg_ids* attribute is honored.
- **defined_tags** (Optional): Defined tags for this Recovery Service subnet.
- **freeform_tags** (Optional): Freeform tags for this Recovery Service subnet.

### <a name="protection-policies">Protection Policies</a>

Each entry in **protection_policies** creates an *oci_recovery_protection_policy* resource with these attributes:

- **compartment_id** (Optional): Compartment OCID or *compartments_dependency* key. Falls back to *default_compartment_id*.
- **display_name** (Required): Display name for the protection policy.
- **backup_retention_period_in_days** (Required): Maximum number of days to retain protected-database backups.
- **must_enforce_cloud_locality** (Optional): Retains backups in the cloud service environment where the protected database is provisioned when set to *true*. Defaults to *false*.
- **policy_locked_date_time** (Optional): RFC 3339 timestamp at which the policy retention period becomes locked.
- **defined_tags** (Optional): Defined tags for this protection policy.
- **freeform_tags** (Optional): Freeform tags for this protection policy.

### <a name="protected-databases">Protected Databases</a>

Each entry in **protected_databases** creates an *oci_recovery_protected_database* resource with these attributes:

- **compartment_id** (Optional): Compartment OCID or *compartments_dependency* key. Falls back to *default_compartment_id*.
- **display_name** (Required): Display name for the protected database.
- **password** (Optional): Literal password used to register the protected database. The module marks the value as sensitive.
- **password_secret_id** (Optional): OCI Vault secret OCID or **secrets_dependency** key containing the password. The module reads and base64-decodes the current secret version, then marks the resulting value as sensitive.

Define exactly one of **password** or **password_secret_id** for each protected database.

Prefer **password_secret_id** to avoid committing a literal password to Git and to centralize password rotation and audit activity in OCI Vault. Regardless of the source, Terraform retrieves the password and stores it in the Terraform state file. Treat the state as sensitive data and protect it with an encrypted backend and appropriately restricted access.
- **database_unique_name** (Required): Unique database name for the protected database.
- **protection_policy_id** (Required): Protection-policy OCID, key from **protection_policies**, or an OCI predefined policy label: *Platinum*, *Gold*, *Silver*, or *Bronze*. Leading and trailing whitespace is ignored for every supported form. Labels are also matched case-insensitively and map directly to fixed Oracle predefined policy OCIDs; no data-source lookup is performed. The predefined policy OCIDs are the same across OCI regions and tenancies.
- **recovery_subnet_ids** (Required): List of Recovery Service subnet OCIDs or keys from **recovery_subnets**.
- **database_id** (Required): Database OCID or key from *databases_dependency.databases*.
- **database_size** (Required): The size of the protected database. "XS" - Less than 5GB, "S" - 5GB to 50GB, "M" - 50GB to 500GB, "L" - 500GB to 1TB, "XL" - 1TB to 5TB, "XXL" - Greater than 5TB.
- **deletion_schedule** (Optional): Preferred deletion schedule after the source database is terminated. OCI default schedule is "DELETE_AFTER_72_HOURS", meaning the delete operation can occur 72 hours (3 days) after the source database is terminated. The alternate schedule is "DELETE_AFTER_RETENTION_PERIOD". Specify this option if you want to delete a protected database only after the policy-defined backup retention period expires.
- **ship_redo_logs** (Optional): *true* indicates that the protected database is configured to use Real-time data protection, and redo-data is sent from the protected database to Recovery Service. Real-time data protection substantially reduces the window of potential data loss that exists between successive archived redo log backups.  Defaults to *false*.
- **subscription_id** (Optional): Cloud service subscription OCID associated with the protected database.
- **defined_tags** (Optional): Defined tags for this protected database.
- **freeform_tags** (Optional): Freeform tags for this protected database.

### <a name="external-dependencies">External Dependencies</a>

External dependencies let configuration values use stable map keys instead of literal OCIDs.

- **compartments_dependency** (Optional): Map of externally managed compartments. A **default_compartment_id**, **iam_policy_compartment_id**, or resource **compartment_id** that does not start with *ocid1* is resolved as a key from this map.
  - **id** (Required): Compartment OCID for the map entry.
- **network_dependency** (Optional): Object containing external network maps.
  - **vcns** (Optional): Map whose entries describe externally managed VCNs.
    - **id** (Required): VCN OCID for the map entry.
  - **subnets** (Optional): Map whose entries describe externally managed subnets.
    - **id** (Required): Subnet OCID for the map entry.
  - **network_security_groups** (Optional): Map whose entries describe externally managed NSGs.
    - **id** (Required): NSG OCID for the map entry.
- **databases_dependency** (Optional): Object containing external database maps.
  - **databases** (Optional): Map whose entries describe externally managed databases.
    - **id** (Required): Database OCID for the map entry.
- **secrets_dependency** (Optional): Map of externally managed OCI Vault secrets.
  - **id** (Required): Secret OCID for the map entry.

Example:

```hcl
compartments_dependency = {
  DATABASE-CMP = {
    id = "ocid1.compartment.oc1..example"
  }
}

network_dependency = {
  vcns = {
    DATABASE-VCN = {
      id = "ocid1.vcn.oc1..example"
    }
  }
  subnets = {
    DATABASE-SUBNET = {
      id = "ocid1.subnet.oc1..example"
    }
  }
  network_security_groups = {
    DATABASE-NSG = {
      id = "ocid1.networksecuritygroup.oc1..example"
    }
  }
}

databases_dependency = {
  databases = {
    DATABASE-1 = {
      id = "ocid1.database.oc1..example"
    }
  }
}

secrets_dependency = {
  DATABASE-PASSWORD = {
    id = "ocid1.vaultsecret.oc1..example"
  }
}
```

### <a name="outputs">Outputs</a>

When *enable_output* is *true* (the default), the module returns:

- *autonomous_recovery_service_subnets*
- *autonomous_recovery_service_protection_policies*
- *autonomous_recovery_service_protected_databases*

Setting *enable_output* to *false* sets all three outputs to *null*.

## <a name="related">Related Documentation</a>

- [OCI Recovery Service](https://docs.oracle.com/en-us/iaas/recovery-service/index.html)

## <a name="issues">Known Issues</a>

No known issues.
