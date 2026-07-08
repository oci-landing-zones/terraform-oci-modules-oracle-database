# OCI Landing Zones Autonomous Recovery Service Module

![Landing Zone logo](../landing_zone_300.png)

This module manages Autonomous Recovery Service resources in Oracle Cloud Infrastructure (OCI). Autonomous Recovery Service provides centralized backup storage and protection policies for Oracle databases, including databases that require locality with the cloud service environment where they run.

The module supports external dependencies for compartments, VCNs, subnets, and network security groups so it can consume outputs from landing zone, network, and workload stacks.

- [Features](#features)
- [Requirements](#requirements)
- [How to Invoke the Module](#invoke)
- [Examples](#examples)
- [Module Functioning](#functioning)
  - [Recovery Service Subnets](#recovery-service-subnets)
  - [Protection Policies](#protection-policies)
  - [External Dependencies](#external-dependencies)
- [Related Documentation](#related)
- [Known Issues](#issues)

## <a name="features">Features</a>

The following features are currently supported by the module:

- Recovery Service subnet registration for a VCN.
- Network Security Group association for Recovery Service subnets.
- Custom protection policies with retention periods from 14 to 95 days.
- Cloud locality enforcement for protection policies.
- Retention lock date configuration for protection policies.
- Support for external dependencies for compartments, VCNs, subnets, and network security groups.

## <a name="requirements">Requirements</a>

### Terraform Version >= 1.5.0

This module requires Terraform binary version 1.5.0 or greater.

### IAM Permissions

This module requires permissions to manage Recovery Service resources and use the network resources associated with Recovery Service subnets:

```text
Allow group <GROUP-NAME> to manage recovery-service-family in compartment <ARS-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use vcns in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use subnets in compartment <NETWORK-COMPARTMENT-NAME>
Allow group <GROUP-NAME> to use network-security-groups in compartment <NETWORK-COMPARTMENT-NAME>
```

Some database service environments require service policies for the Database and Recovery Service control planes, such as:

```text
Allow service database to manage recovery-service-family in tenancy
Allow service database to manage tagnamespace in tenancy
Allow service rcs to manage recovery-service-family in tenancy
Allow service rcs to manage virtual-network-family in tenancy
```

If subscription-linked database services are used, add the required subscription policy for the target service environment.

## <a name="invoke">How to Invoke the Module</a>

Terraform modules can be invoked locally or remotely.

For invoking the module locally, set the module `source` attribute to the module file path. Example:

```hcl
module "autonomous_recovery_service" {
  source = "../.."

  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
  compartments_dependency                   = var.compartments_dependency
  network_dependency                        = var.network_dependency
}
```

For invoking the module remotely, set the module `source` attribute to the `autonomous-recovery-service` module folder in this repository:

```hcl
module "autonomous_recovery_service" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-exadata/autonomous-recovery-service"

  autonomous_recovery_service_configuration = var.autonomous_recovery_service_configuration
  compartments_dependency                   = var.compartments_dependency
  network_dependency                        = var.network_dependency
}
```

To refer to a specific module version, add `?ref=<version>` to the `source` attribute value:

```hcl
source = "github.com/oci-landing-zones/terraform-oci-modules-exadata/autonomous-recovery-service?ref=v1.0.0"
```

## <a name="examples">Examples</a>

The [examples](./examples/) folder contains:

- [Exadata Database Service on Dedicated Infrastructure with Autonomous Recovery Service](./examples/exadb-d-with-ars/README.md).

## <a name="functioning">Module Functioning</a>

The module defines a top-level variable used to manage Autonomous Recovery Service resources:

- **autonomous_recovery_service_configuration**: for managing Recovery Service subnets and protection policies.

The configuration object contains default attributes and resource maps. Attribute values that expect OCIDs can receive either literal OCIDs or keys to external dependency maps.

The `default_` attributes are:

- **default_compartment_id**: Default compartment for all resources. Can be overridden by `compartment_id` in each resource.
- **default_defined_tags**: Default defined tags for all resources. Can be overridden or extended by resource-level `defined_tags`.
- **default_freeform_tags**: Default freeform tags for all resources. Can be overridden or extended by resource-level `freeform_tags`.

### <a name="recovery-service-subnets">Recovery Service Subnets</a>

Recovery Service subnets are managed using the **recovery_service_subnets** map.

Each Recovery Service subnet object supports:

- **compartment_id**: Optional compartment OCID or dependency key. Defaults to `default_compartment_id`.
- **display_name**: Recovery Service subnet display name.
- **vcn_id**: VCN OCID or key in `network_dependency.vcns`.
- **subnet_ids**: List of subnet OCIDs or keys in `network_dependency.subnets`.
- **nsg_ids**: Optional list of network security group OCIDs or keys in `network_dependency.network_security_groups`.
- **defined_tags**: Optional defined tags.
- **freeform_tags**: Optional freeform tags.

OCI supports a single Recovery Service subnet per VCN.

### <a name="protection-policies">Protection Policies</a>

Protection policies are managed using the **protection_policies** map.

Each protection policy object supports:

- **compartment_id**: Optional compartment OCID or dependency key. Defaults to `default_compartment_id`.
- **display_name**: Protection policy display name.
- **backup_retention_period_in_days**: Backup retention period. Supported range is 14 to 95 days.
- **must_enforce_cloud_locality**: Optional cloud locality enforcement flag. Use `true` for policies that must keep backups in the same cloud service environment where the database runs.
- **policy_locked_date_time**: Optional RFC3339 date and time for retention lock to take effect.
- **defined_tags**: Optional defined tags.
- **freeform_tags**: Optional freeform tags.

The cloud locality setting cannot be changed after a protection policy is created.

### <a name="external-dependencies">External Dependencies</a>

The following dependencies are supported:

- **compartments_dependency**: A map of externally managed compartments. Each object must contain at least an `id` attribute with the compartment OCID.
- **network_dependency.vcns**: A map of externally managed VCNs. Each object must contain at least an `id` attribute with the VCN OCID.
- **network_dependency.subnets**: A map of externally managed subnets. Each object must contain at least an `id` attribute with the subnet OCID.
- **network_dependency.network_security_groups**: A map of externally managed network security groups. Each object must contain at least an `id` attribute with the NSG OCID.

Example:

```hcl
autonomous_recovery_service_configuration = {
  default_compartment_id = "DATABASE-CMP"

  recovery_service_subnets = {
    "ARS-SUBNET" = {
      display_name = "ars-subnet"
      vcn_id       = "DATABASE-VCN"
      subnet_ids   = ["DATABASE-BACKUP-SUBNET"]
      nsg_ids      = ["DATABASE-BACKUP-NSG"]
    }
  }

  protection_policies = {
    "BRONZE-LOCAL" = {
      display_name                    = "Bronze_with_cloud_locality"
      backup_retention_period_in_days = 14
      must_enforce_cloud_locality     = true
    }
  }
}
```

## <a name="related">Related Documentation</a>

- [OCI Terraform provider: Recovery Service subnet](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/latest/docs/r/recovery_recovery_service_subnet.html)
- [OCI Terraform provider: protection policy](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/latest/docs/r/recovery_protection_policy.html)
- [OCI Autonomous Recovery Service](https://docs.oracle.com/en-us/iaas/recovery-service/)

## <a name="issues">Known Issues</a>

This module creates Autonomous Recovery Service resources. It does not enable backups for a database. Configure database backup usage in the database module or resource by setting `db_backup_config.backup_destination_details.type = "DBRS"` and `dbrs_policy_id` to either a protection policy OCID or a protection policy key resolved through the Exadata module `recovery_service_dependency` input.
