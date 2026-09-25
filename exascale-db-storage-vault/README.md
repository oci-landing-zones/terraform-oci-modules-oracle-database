# OCI Landing Zones Exascale DB Storage Vault Module

This module manages `oci_database_exascale_db_storage_vault`. An Exascale DB
Storage Vault is an OCI Database storage resource; it is not an OCI Vault/KMS
vault or secret store.

The module is intentionally neutral: it creates vaults without creating a VM
Cluster. A vault can be used by ExaDB-XS or, when associated with a Cloud
Exadata Infrastructure, by a Dedicated Infrastructure workflow.

## Use as a child module

`exadb-xs` and `exadata-database` invoke this module internally for locally
configured vaults. The parent supplies configuration and dependencies; this
module owns the OCI resource implementation, validation, tags, and
dependency-shaped outputs.

```hcl
module "storage_vault" {
  source = "../exascale-db-storage-vault"

  compartments_dependency = {
    database = { id = "ocid1.compartment.oc1..example" }
  }

  exascale_db_storage_vaults_configuration = {
    default_compartment_id = "database"
    exascale_db_storage_vaults = {
      shared = {
        availability_domain                = "example:AD-1"
        display_name                       = "shared-exascale-vault"
        high_capacity_database_storage_gbs = 300
      }
    }
  }
}
```

## Dedicated Infrastructure mode

For a vault associated with an existing or locally-created Cloud Exadata
Infrastructure, set `exadata_infrastructure_id` to an OCID or a key in
`exadata_infrastructure_dependency`. Terraform then orders the vault after the
Infrastructure in the same plan when the parent passes the generated ID.

```hcl
exascale_db_storage_vaults_configuration = {
  exascale_db_storage_vaults = {
    dedicated = {
      availability_domain                = "example:AD-1"
      display_name                       = "dedicated-exascale-vault"
      high_capacity_database_storage_gbs = 2000
      exadata_infrastructure_id          = "existing-infrastructure"
    }
  }
}
```

This module does not make a VM Cluster use the vault. A consumer must pass the
published vault ID to its own OCI VM Cluster resource. For ExaDB-XS that is
mandatory per cluster. The current Exadata-D parent creates and publishes a
Dedicated Infrastructure vault, but does not yet change the existing Cloud VM
Cluster contract to consume it.

## Outputs and ownership

`exascale_db_storage_vault_dependency` publishes a stable map with `id` and
`compartment_id`. One Terraform state must own each vault. Other states or
modules must consume its published dependency map rather than declaring the
same vault again.

## Requirements and validation

- Terraform `>= 1.5.0` and OCI provider `>= 8.0.0`.
- A non-Dedicated vault requires 300–100,000 GB.
- A Dedicated Infrastructure-associated vault requires at least 2,000 GB; its
  maximum is still a live-service constraint.
- Flash Cache percentage is zero or 34–300; autoscaling limit cannot be lower
  than requested capacity.
- `defined_tags` are ignored for operational compatibility; `freeform_tags`
  remain Terraform-managed.

See [SPEC.md](./SPEC.md) for the contract and
[examples/quickstart](./examples/quickstart) for a minimal standalone
configuration. Orchestrator wiring for the Exadata-D vault output remains a
separate coordinated change.
