# OCI Landing Zones ExaDB-XS Module

This module manages Oracle Exadata Database Service on Exascale Infrastructure
(ExaDB-XS) resources:

- Exascale DB Storage Vaults through the reusable
  `../exascale-db-storage-vault` child module.
- ExaDB-XS VM Clusters through `oci_database_exadb_vm_cluster`.
- Database homes, container databases, and pluggable databases through the local
  `../common-database` module.

An Exascale DB Storage Vault is an OCI Database resource. It is not an OCI Vault,
KMS vault, or secret store.

## Requirements

- Terraform `>= 1.5.0`.
- OCI provider `>= 8.0.0`.
- OCI permissions and service capacity for the selected availability domain.

The provider floor is deliberately explicit: the module uses only attributes and
nested blocks present in the OCI provider 8.0.0 schema.

## Configuration and dependencies

`exadb_xs_configuration` is a typed optional object containing defaults and two
stable-keyed maps: `exascale_db_storage_vaults` and `exadb_vm_clusters`. The
vault map is forwarded to the reusable child module; the cluster map remains
owned by ExaDB-XS. Map keys are Terraform identities; display names are never
used as resource addresses.

References accept either literal OCIDs or logical keys:

| Value | Literal OCID prefix | Logical dependency map |
| --- | --- | --- |
| Compartment | `ocid1.compartment.` or `ocid1.tenancy.` | `compartments_dependency` |
| Subnet | `ocid1.subnet.` | `network_dependency.subnets` |
| NSG | `ocid1.networksecuritygroup.` | `network_dependency.network_security_groups` |
| Subscription | `ocid1.` | `subscription_dependency` |
| Storage vault | `ocid1.exascaledbstoragevault.` | local vault key or `exadb_xs_dependency.exascale_db_storage_vaults` |

`kms_dependency`, `secrets_dependency`, and `recovery_service_dependency` are
passed unchanged to `common-database`. They are not inputs to an Exascale DB
Storage Vault resource.

## Invocation

```hcl
module "exadb_xs" {
  source = "../exadb-xs"

  compartments_dependency = {
    database = { id = "ocid1.compartment.oc1..example" }
  }
  network_dependency = {
    subnets = {
      client = { id = "ocid1.subnet.oc1..example" }
      backup = { id = "ocid1.subnet.oc1..example" }
    }
    network_security_groups = {
      database = { id = "ocid1.networksecuritygroup.oc1..example" }
    }
  }

  exadb_xs_configuration = {
    default_compartment_id = "database"
    exascale_db_storage_vaults = {
      primary = {
        availability_domain                = "example:AD-1"
        display_name                       = "primary-xs-vault"
        high_capacity_database_storage_gbs = 1000
      }
    }
    exadb_vm_clusters = {
      primary = {
        availability_domain          = "example:AD-1"
        backup_subnet_id             = "backup"
        display_name                 = "primary-xs-cluster"
        exascale_db_storage_vault_id = "primary"
        grid_image_id                = "ocid1.image.oc1..example"
        hostname                     = "exaxs01"
        shape                        = "EXADB_XS"
        ssh_public_keys              = ["ssh-rsa example"]
        subnet_id                    = "client"
        node_names                   = ["node-1", "node-2"]
        node_config = {
          enabled_ecpu_count_per_node              = 8
          total_ecpu_count_per_node                = 8
          vm_file_system_storage_size_gbs_per_node = 220
        }
        nsg_ids = ["database"]
      }
    }
  }
}
```

The examples folder contains complete input scaffolding. Values such as image IDs,
shapes, and capacity must be valid for the target region and availability domain.

## Database resources

The module forwards `cloud_db_homes_configuration`, `databases_configuration`, and
`pluggable_databases_configuration` unchanged to `../common-database`, and passes
the local/external ExaDB-XS VM Cluster map as `vm_cluster_dependency`.

Those three inputs deliberately use `any` at this outer boundary: the typed
contracts and their detailed DB Home, CDB, and PDB validations have one source
of truth in `common-database`. This avoids maintaining a third duplicate of the
same large contract. They therefore accept the same configuration shape as
`exadata-database` and fail during the same Terraform plan when the child
module validates them.

Database version compatibility with an ExaDB-XS storage mode and Grid Image is
enforced by OCI. It remains a test-tenancy check until the service behavior is
verified with authenticated evidence.

`common-database` accepts both `ocid1.cloudvmcluster.` and
`ocid1.exadbvmcluster.` targets. Consequently, a DB Home can reference an
ExaDB-XS VM Cluster by local key, external dependency key, or literal OCID.

## Outputs

- `exascale_db_storage_vaults` (forwarded from the reusable vault child module)
- `exadb_vm_clusters`
- `database_homes`, `databases`, `pluggable_databases`
- `exadb_xs_resources` and its alias `exadb_xs_dependency`

The two dependency-shaped outputs contain stable maps with `id` and
`compartment_id`, plus the forwarded common-database resource maps.

## Lifecycle behavior

For operational compatibility with `exadata-database`, the VM Cluster ignores
changes to its Grid setup image ID (`grid_image_id`), its operating-system
`system_version`, and all `defined_tags`. The Storage Vault child module also ignores all
`defined_tags`. `freeform_tags` remain Terraform-managed, as do topology, node
configuration, storage vault IDs, shapes, network configuration, security
attributes, capacity, autoscaling, and Flash Cache settings.

`grid_image_id` is still used to create the VM Cluster, but later changes to it
in OCI or HCL are ignored. `gi_version` is OCI-reported computed metadata, so it
does not need an `ignore_changes` entry. Confirm the defined-tag lifecycle
policy with the module owners before a published release.

## Validation scope

Terraform validation proves input shape, local resolution, and provider schema
compatibility. The module additionally fails early for documented static VM
Cluster limits (node count, ECPU range/multiples including zero enabled ECPUs,
per-node filesystem minimum by storage mode, hostname format, storage-mode
and license values, SCAN port, and ZPR attribute count). The vault child module
validates XS vault capacity and Flash Cache ranges. Neither module proves regional service capacity, supported
image/shape combinations, an existing vault's storage-mode compatibility, or the
OCI service behavior of DB homes on ExaDB-XS. No example or test performs an
OCI apply.
