# ExaDB-XS Module Specification

## Managed resources

| Resource | Address | Iteration identity |
| --- | --- | --- |
| Exascale DB Storage Vault | `module.exascale_db_storage_vault` | `exascale_db_storage_vaults` caller key |
| ExaDB-XS VM Cluster | `oci_database_exadb_vm_cluster.these` | `exadb_vm_clusters` caller key |
| Database resources | `module.common_database` | Existing common-database caller keys |

## Creation order

1. Resolve Landing Zone dependencies and local configuration maps.
2. Invoke `../exascale-db-storage-vault` to create locally configured vaults.
3. Create ExaDB-XS VM Clusters with local, external, or literal storage-vault references.
4. Invoke `../common-database` with the merged ExaDB-XS VM Cluster dependency map.

## Provider 8.0.0 contract

The reusable storage-vault child module uses only its required availability domain,
compartment, display name, and `high_capacity_database_storage` block, plus
optional 8.0.0 fields for capacity, tags, subscription, time zone, description,
and optional Cloud Exadata Infrastructure association.

The VM-cluster resource uses only its required 8.0.0 fields and required
`node_config` block. `node_resource` is generated from validated node names.
Computed-only provider fields are never configuration inputs.

## Fail-fast behavior

The vault child module rejects invalid ExaDB-XS vault capacity and Flash Cache
percentages, nonblank/invalid VM Cluster names and hostnames, VM counts outside
1–10, invalid ECPU ranges or multiples, filesystem storage below the
Smart/Block minimums, invalid storage modes and license API
constants, invalid SCAN TCP ports, more than three ZPR attributes, and empty SSH
key lists. Resource preconditions reject unresolved dependencies or incorrect
OCID kinds.

The module does not claim to validate live OCI properties such as vault storage
mode compatibility, Grid Infrastructure release, subnet CIDR overlap, hostname
uniqueness, or availability-domain capacity. These require a credentialed plan
or an apply in a suitable test tenancy.

`cloud_db_homes_configuration`, `databases_configuration`, and
`pluggable_databases_configuration` are forwarded unchanged to
`common-database`, which remains the single typed and validated contract for
Oracle Homes, CDBs, and PDBs. For a local-key reference to a Smart Storage
cluster, this module additionally rejects an explicit DB Home `db_version`
outside the 26ai family. Image-OCID-only compatibility needs OCI evidence.

For operations compatibility, the VM Cluster ignores `grid_image_id`,
operating-system `system_version`, and all `defined_tags`; the Storage Vault
child module ignores all `defined_tags`. OCI-reported `gi_version` is computed-only and needs
no lifecycle ignore. `freeform_tags` remain managed by Terraform.

## Output contract

`exadb_xs_resources` and `exadb_xs_dependency` have this stable shape:

```hcl
{
  exascale_db_storage_vaults = map(object({ id = string, compartment_id = string }))
  exadb_vm_clusters          = map(object({ id = string, compartment_id = string }))
  database_homes             = map(any)
  databases                  = map(any)
  pluggable_databases        = map(any)
}
```

When no resource is configured, each internal collection is an empty map.
