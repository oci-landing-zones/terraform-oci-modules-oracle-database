# OCI Landing Zones Common Database Module

## Overview

This module creates OCI Database Homes, container databases (CDBs), and pluggable databases (PDBs). It is independent of the infrastructure module that creates the target VM cluster or DB system, so it can be composed with `exadata-database` or with external database infrastructure modules.

Resource references accept either literal OCIDs or logical keys from dependency inputs. A DB Home can target a Cloud VM Cluster with `vm_cluster_id` and `vm_cluster_dependency`, or a DB System with `db_system_id` and `db_system_dependency`. Only one target can be configured for a DB Home.

## Usage

```hcl
module "common_database" {
  source = "../common-database"

  vm_cluster_dependency = {
    primary = {
      id = module.database_infrastructure.vm_cluster_id
    }
  }

  cloud_db_homes_configuration = {
    home = {
      display_name  = "DB-HOME-1"
      db_version    = "19.0.0.0"
      source        = "VM_CLUSTER_NEW"
      vm_cluster_id = "primary"
    }
  }

  databases_configuration = {
    cdb = {
      source     = "NONE"
      db_home_id = "home"
      database = {
        admin_password = var.database_admin_password
        db_name        = "CDB1"
        pdb_name       = "PDB1"
      }
    }
  }

  pluggable_databases_configuration = {
    reporting = {
      container_database_id = "cdb"
      pdb_name              = "REPORTING"
      pdb_admin_password    = var.pdb_admin_password
      tde_wallet_password   = var.tde_wallet_password
    }
  }
}
```

For a DB System target, replace `vm_cluster_dependency` and `vm_cluster_id` with `db_system_dependency` and `db_system_id` respectively, and select the OCI-supported DB Home `source` for that target.

## Inputs

- `cloud_db_homes_configuration`: DB Homes to create. Existing inline `database` entries remain supported for compatibility, but new configurations should use `databases_configuration`.
- `databases_configuration`: Container databases to create. `db_home_id` accepts a local DB Home key, a key from `database_dependency.database_homes`, or a DB Home OCID.
- `pluggable_databases_configuration`: Additional PDBs to create. `container_database_id` accepts a local database key, a key from `database_dependency.databases`, or a database OCID.
- `database_dependency`: External DB Homes, databases, and PDBs used by logical key.
- `vm_cluster_dependency`: External Cloud VM Clusters used by logical key.
- `db_system_dependency`: External DB Systems used by logical key.
- `kms_dependency`: External KMS keys used by logical key.
- `recovery_service_dependency`: External Recovery Service protection policies, either as a direct map or under `protection_policies`.
- `default_defined_tags` and `default_freeform_tags`: Default tags for created resources.
- `enable_output`: Enables module outputs. Defaults to `true`.

The complete typed configuration contract and validation rules are declared in [`variables.tf`](./variables.tf).

## Outputs

- `database_homes`, `databases`, and `pluggable_databases`: Raw resource maps. These outputs are sensitive.
- `database_resources`: Minimal ID-only maps intended for dependency handoff.
- `database_dependency`: Alias of `database_resources` for direct downstream consumption.

## Upgrade from `exadata-database`

Existing callers do not need to change their Exadata module inputs. The Exadata wrapper passes its VM clusters and external dependencies to this module and keeps the prior outputs. The wrapper also contains `moved` blocks that migrate the three resource collections to their new child-module addresses. Review the first plan after upgrading; it should show address moves rather than destroy/create actions for unchanged resources.
