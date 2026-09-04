# OCI Landing Zones Common Database Module

![Landing Zone logo](../landing_zone_300.png)

This module manages OCI Database Homes, Container Databases (CDBs), and Pluggable Databases (PDBs). Use it when the target Cloud VM Cluster or DB System already exists and is managed by another stack or module. It does not create Cloud Exadata Infrastructure, Cloud VM Clusters, or DB Systems.

Resource references accept literal OCIDs or logical keys resolved through dependency inputs. The module can target either a Cloud VM Cluster or a DB System; each DB Home must select exactly one target.

Check [module specification](./SPEC.md) for the complete typed contract, managed resources, and outputs. Check the [examples](./examples/) folder for module usage.

- [Features](#features)
- [Requirements](#requirements)
- [How to Invoke the Module](#invoke)
- [Module Functioning](#functioning)
  - [Database Homes](#database-homes)
  - [Container Databases](#container-databases)
  - [Pluggable Databases](#pluggable-databases)
  - [External Dependencies](#external-dependencies)
  - [Outputs](#outputs)
- [Related Documentation](#related)
- [Known Issues](#issues)

## <a name="features">Features</a>

The module supports:

- Database Homes on existing Cloud VM Clusters or DB Systems.
- Standalone Container Databases and additional Pluggable Databases.
- Logical-key or literal-OCID references to locally managed and external DB Homes, CDBs, PDBs, VM Clusters, DB Systems, KMS keys, and Recovery Service protection policies.
- Default and per-resource defined and freeform tags.
- Sensitive raw resource outputs and minimal ID-only dependency outputs for downstream stacks.

## <a name="requirements">Requirements</a>

### Terraform version >= 1.3.0

The module requires Terraform 1.3.0 or later and the default `oci` provider configuration. The identity applying the module needs OCI permissions to manage the selected Database Service resources and to use the referenced VM Cluster, DB System, encryption keys, and Recovery Service protection policies.

## <a name="invoke">How to Invoke the Module</a>

Terraform modules can be invoked locally or remotely.

For local use, set `source` to the module path:

```hcl
module "common_database" {
  source = "../common-database"

  cloud_db_homes_configuration      = var.cloud_db_homes_configuration
  databases_configuration           = var.databases_configuration
  pluggable_databases_configuration = var.pluggable_databases_configuration
  vm_cluster_dependency             = var.vm_cluster_dependency
}
```

For remote use, refer to this module directory in the repository:

```hcl
module "common_database" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-exadata//common-database?ref=v1.2.0"

  cloud_db_homes_configuration      = var.cloud_db_homes_configuration
  databases_configuration           = var.databases_configuration
  pluggable_databases_configuration = var.pluggable_databases_configuration
  vm_cluster_dependency             = var.vm_cluster_dependency
}
```

For a DB System target, use `db_system_dependency` and `db_system_id` instead of `vm_cluster_dependency` and `vm_cluster_id`, and select the OCI-supported DB Home `source` for that target.

## <a name="functioning">Module Functioning</a>

The module manages three optional configuration maps. Map keys identify resources and can be used by later entries in the same stack.

- `cloud_db_homes_configuration`: Database Homes to create.
- `databases_configuration`: Container Databases to create.
- `pluggable_databases_configuration`: Additional PDBs to create.

### <a name="database-homes">Database Homes</a>

Each Database Home selects one target: `vm_cluster_id` for a Cloud VM Cluster or `db_system_id` for a DB System. The target can be a literal OCID or a key from `vm_cluster_dependency` or `db_system_dependency`. A Database Home cannot target both.

The legacy inline `cloud_db_homes_configuration[*].database` block is retained only for Exadata Database 1.1.0 upgrade compatibility. New CDB configurations must use `databases_configuration`.

The module does not manage later DB Home software version or image changes. OCI provenance tags `Oracle-Tags.CreatedBy` and `Oracle-Tags.CreatedOn` are ignored on the DB Home and its legacy inline CDB; other defined tags and all freeform tags remain managed by Terraform. Administration, backup TDE, and TDE wallet passwords in the legacy inline CDB are sensitive creation-time values.

### <a name="container-databases">Container Databases</a>

Each `databases_configuration` entry creates a standalone CDB. Its `db_home_id` accepts a Database Home key created in this module, a key from `database_dependency.database_homes`, or a DB Home OCID. The `source` attribute supports `NONE`, `DB_BACKUP`, and `DATAGUARD`; the module validates source-specific required inputs before creation.

`database.admin_password`, `database.backup_tde_password`, `database.source_tde_wallet_password`, and `database.tde_wallet_password` are sensitive creation-time values. In particular, `backup_tde_password` is used only for a `DB_BACKUP` restore and is not reapplied later. The module does not manage later CDB DB Home changes, which allows an out-of-place DB Home patch to remain in place. The OCI provenance tags `Oracle-Tags.CreatedBy` and `Oracle-Tags.CreatedOn` are ignored; customer-defined and freeform tags remain managed.

OCI tag defaults can add tenancy-specific defined tags when a CDB is created. Declare those tags in `default_defined_tags` or `database.defined_tags` when Terraform should manage them. Direct callers can instead list selected fully qualified keys in the OCI provider's `ignore_defined_tags` setting when Terraform should intentionally ignore them. Do not ignore the complete `database.defined_tags` map, because that would also hide customer-managed tag changes.

### <a name="pluggable-databases">Pluggable Databases</a>

Each `pluggable_databases_configuration` entry creates a PDB. Its `container_database_id` accepts a CDB key created in this module, a key from `database_dependency.databases`, or a CDB OCID. Changes that move a PDB to a different CDB remain visible in the Terraform plan.

`container_database_admin_password`, `pdb_admin_password`, and `tde_wallet_password` are sensitive creation-time values. OCI provenance tags are ignored, while customer-defined and freeform tags remain managed.

### <a name="external-dependencies">External Dependencies</a>

External dependencies let configuration values use stable map keys instead of literal OCIDs.

- `database_dependency`: External DB Homes, CDBs, and PDBs.
- `vm_cluster_dependency`: External Cloud VM Clusters.
- `db_system_dependency`: External DB Systems.
- `kms_dependency`: External encryption keys.
- `recovery_service_dependency`: Recovery Service protection policies, supplied as a direct map or under `protection_policies`.

Use `database_resources` or `database_dependency` from a producing Common Database module as the corresponding `database_dependency` input of a downstream module.

### <a name="outputs">Outputs</a>

When `enable_output` is `true` (the default), the module returns:

- `database_homes`, `databases`, and `pluggable_databases`: sensitive raw resource maps.
- `database_resources`: minimal ID-only maps for dependency handoff.
- `database_dependency`: alias of `database_resources` for downstream consumption.

Setting `enable_output` to `false` sets the outputs to `null`.

## <a name="related">Related Documentation</a>

- [OCI Database Service](https://docs.oracle.com/en-us/iaas/database/)
- [Common Database module specification](./SPEC.md)

## <a name="issues">Known Issues</a>

No known issues.
