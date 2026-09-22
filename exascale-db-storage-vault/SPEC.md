# Exascale DB Storage Vault Module Specification

## Managed resource

| Resource | Address | Identity |
| --- | --- | --- |
| Exascale DB Storage Vault | `oci_database_exascale_db_storage_vault.these` | Caller map key |

## Input contract

`exascale_db_storage_vaults_configuration` is an optional typed object with
default compartment/tag values and an `exascale_db_storage_vaults` map. Each
vault requires an availability domain, display name, and database storage size.

The optional `exadata_infrastructure_id` selects Dedicated Infrastructure mode.
It accepts a literal `ocid1.cloudexadatainfrastructure.` OCID or a key in
`exadata_infrastructure_dependency`. It is omitted for the ExaDB-XS path.

`compartments_dependency` and `subscription_dependency` resolve logical keys.
All maps use stable semantic keys, never display names, for Terraform identity.

## Output contract

```hcl
exascale_db_storage_vault_dependency = {
  vault_key = {
    id             = "ocid1.exascaledbstoragevault..."
    compartment_id = "ocid1.compartment..."
  }
}
```

The same map is also available as `exascale_db_storage_vault_resources`.

## Lifecycle and validation

The resource ignores `defined_tags` and manages all other configured fields.
Variable validation covers static capacity, Flash Cache, display-name, and
autoscaling constraints. Resource preconditions validate resolved compartment,
subscription, and optional Dedicated Infrastructure OCID kinds.

The module cannot prove live OCI capacity, quota, policy, or a vault's future
storage-mode compatibility with a particular VM Cluster. Consumers must enforce
their cluster-specific rules and verify service behavior in an approved test
tenancy.
