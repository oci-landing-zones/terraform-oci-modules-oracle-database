# Unreleased Release Notes - 1.3.1

## Updates

1. Fixed unnecessary replacement of imported standalone CDBs by ignoring changes to their creation-time `source` after creation. ([#19](https://github.com/oci-landing-zones/terraform-oci-modules-oracle-database/issues/19))
2. Fixed unnecessary PDB replacement when the creation-time `should_create_pdb_backup` or `should_pdb_admin_account_be_locked` flags differ from state. Changes to `container_database_id` remain managed. ([#20](https://github.com/oci-landing-zones/terraform-oci-modules-oracle-database/issues/20))
3. Accepted an empty `cloud_exadata_infrastructures_configuration` object for deployments using existing infrastructure and fixed validation of omitted database and storage server types on Terraform 1.5.7. ([#17](https://github.com/oci-landing-zones/terraform-oci-modules-oracle-database/issues/17))
4. Fixed planning with sensitive password values in Common Database and Exadata Database. Common Database owns validation of DB Home, CDB, and PDB inputs.
5. Fixed Exadata Availability Domain and DB server lookups when the relevant compartment or infrastructure OCID is known only after apply.
6. Fixed ADB Shared / Serverless TDE Vault and existing-key lookups when dependency OCIDs are known only after apply. Updated the Vaults dependency to v0.2.4 to support creating a new TDE key when the Vault OCID is also deferred. ([Vaults issue #22](https://github.com/oci-landing-zones/terraform-oci-modules-security/issues/22))
7. Added optional `create`, `update`, and `delete` timeouts per Cloud VM Cluster. Omitted values use the OCI provider defaults. See [Cloud VM Clusters](./exadata-database/README.md#cloud-vm-clusters) for provider behavior on updates and deletions. ([#15](https://github.com/oci-landing-zones/terraform-oci-modules-oracle-database/issues/15))
8. Added optional `ignore_cpu_changes` per Cloud VM Cluster for external CPU scaling, including Oracle Dynamic Scaling (ODyS). Enabling it on an existing Terraform-managed cluster requires a per-cluster `moved` block. See [Cloud VM Clusters](./exadata-database/README.md#cloud-vm-clusters).

## Upgrading to 1.3.1

- From 1.1.0, keep existing inline CDB configuration in its DB Home. Terraform moves the resource addresses as described in [Updating from 1.1.0](./exadata-database/README.md#updating-from-110).
- From 1.2.0 or 1.3.0, keep existing inputs and resource addresses when leaving `ignore_cpu_changes` omitted or `false`. If you tested the 1.2.1 candidate with external CPU management enabled, keep the flag and any existing per-cluster `moved` blocks when upgrading to 1.3.1. Version 1.3.0 predates that resource address and can plan replacements for those clusters and their dependents.
- Module-managed `ocilz-terraform-module` tags can show in-place updates to 1.3.1. Existing ADB TDE keys created by the Vaults child module can also show a tag update to reflect Vaults v0.2.4. Keep the provider version from your lockfile for the first upgrade plan and review the actions before applying.
- Orchestrator users need module source references that select 1.3.1 to use these fixes and options. The published Orchestrator v2.4.1 still references `release-1.2.0` for Exadata and ADB. Its module calls pass Vault and encryption-key dependencies where supported. For password secrets through that release, supply Vault secret OCIDs directly. Logical password secret keys require a direct module call with `secrets_dependency`. Keep the provider version compatible with the Orchestrator stack. The OKE module bundled with v2.4.1 constrains the OCI provider to versions below 9.0.0.

# November 5, 2026 Release Notes - 1.3.0

## Updates
1. Added the `base-database` module for single-node Base Database Service DB Systems, with an inline Database Home, database, and initial PDB, plus additional PDBs managed as separate resources.
2. Added direct OCID and logical-key dependency support for compartments, subnets, network security groups, KMS keys, Vault secrets, and Recovery Service protection policies in the Base Database module.
3. Added direct passwords and OCI Vault secret references for database and additional PDB administrator passwords.
4. Added Object Storage and Recovery Service backup destination configuration.
5. Added curated DB System and additional PDB outputs, including DB System dependency outputs for downstream modules.
6. Added Base Database input validation, lifecycle handling, module specification, documentation, and a deployment example.

## Upgrade from 1.2.0

1. This release adds the Base Database module without changing the existing Exadata Database, Common Database, Autonomous Database, or Autonomous Recovery Service modules. For a version-only upgrade, retain the existing configuration and review the first Terraform plan before applying.
2. To use the new module, set the module source to `github.com/oci-landing-zones/terraform-oci-modules-oracle-database//base-database?ref=v1.3.0`. Base Database requires Terraform >= 1.3.0 and OCI provider >= 8.25.0.
3. Base Database administrator passwords resolved from Vault secrets are stored in Terraform state. Protect the state with an encrypted backend and restricted access.

# September 4, 2026 Release Notes - 1.2.0

## Updates
1. Added Exadata Database dependency output for OCI Landing Zones Orchestrator consumption.
2. Added cross-stack Exadata Database dependency support for Exadata infrastructures, VM clusters, DB homes, databases, and pluggable databases.
3. Added KMS dependency support for DB Home and standalone CDB encryption key references.
4. Added external PDB lookup support for PDB clone source references.
5. Fixed optional customer contacts, VM cluster compartment fallback, defined tags defaulting, CDB OCI provenance tag drift, null DB server lists, VM cluster subscription lookup, standalone CDB KMS lookup, PDB password sensitivity handling, and sensitive raw database outputs.
6. Added Autonomous Database dependency output for OCI Landing Zones Orchestrator consumption.
7. Added vault dependency support for Autonomous Database TDE vault references.
8. Updated the Autonomous Database provider alias declaration for Orchestrator module invocation.
9. Fixed Autonomous Database private endpoint IP pass-through.
10. Added the `common-database` module for customers that manage DB Homes, Container Databases, and Pluggable Databases on existing Cloud VM Clusters or DB Systems. Added standalone `databases_configuration` for new Container Databases while retaining compatibility with existing 1.1.0 Exadata Database configurations.
11. Aligned Exadata Database Terraform version requirements with the Orchestrator and Autonomous Database modules.
12. Added Autonomous Database module specification and refreshed examples for ADB Shared / Serverless and ADB Dedicated usage.
13. Fixed Autonomous Database Dedicated handling so serverless TDE vault/key data sources are not read when TDE is inherited from an existing Autonomous Container Database.
14. Added Exadata X11MV support for infrastructure shape `Exadata.X11MV`, database server type `X11MV`, and storage server type `X11MV-HC`.
15. Made the fallback Exadata Availability Domain selection deterministic when `availability_domain` is omitted.
16. Added the Autonomous Recovery Service module for recovery service subnets, protection policies, and protected databases, with optional NSGs and IAM policy creation. Exadata Database supports DBRS handoff for standalone CDBs through `recovery_service_dependency`.
17. Added Exadata Database protection policy resolution for direct and wrapped dependency maps, literal OCID passthrough, standalone database integration, and explicit rejection of unresolved protection policy keys.
18. Added logical-key dependencies for externally managed VM clusters and DB systems.
19. Marked standalone CDB backup TDE passwords as sensitive and ignored OCI provenance tags without suppressing customer tag management.
20. Fixed Exadata Infrastructure default maintenance windows so `custom_action_timeout_in_mins`, `is_custom_action_timeout_enabled`, `is_monthly_patching_enabled`, and `patching_mode` are passed to OCI instead of being discarded during input type conversion.
21. Fixed Exadata Infrastructure and Cloud VM Cluster compartment resolution so a tenancy OCID can be used to provision resources in the root compartment, whether supplied directly, through `default_compartment_id`, or through `compartments_dependency`.

## Upgrade from 1.1.0

1. Existing Exadata Database and Autonomous Database 1.1.0 configurations remain accepted in 1.2.0. For a version-only upgrade, update the module version, retain the existing configuration, and review the first plan before applying. Investigate any unexpected creation, replacement, or destruction of existing resources. See [Updating from 1.1.0](./exadata-database/README.md#updating-from-110).
2. Existing Exadata Database 1.1.0 CDB configurations remain accepted. New CDBs use `databases_configuration` and reference a DB Home by key or OCID.
3. Existing ADB Shared / Serverless TDE configurations can retain Vault OCIDs in `kms_dependency`. For new TDE configurations, use `vaults_dependency` for Vault logical keys and keep encryption keys in `kms_dependency`.
4. Exadata Database raw outputs `database_homes`, `databases`, and `pluggable_databases` are now sensitive. Root modules that re-export them should mark their own outputs as `sensitive = true` or use `exadata_database_resources` for dependency handoff.
5. Exadata Database validates standalone CDB/PDB inputs earlier, including CDB names with special characters, `OBJECT_STORAGE` backup destination spelling, unsupported standalone source encryption fields, and DB Home OCIDs used as PDB container database IDs.
6. Due to a 1.1.0 bug, `networking.private_endpoint_ip` was accepted but was not passed to OCI. In 1.2.0, the value is passed when creating a new ADB Shared / Serverless private endpoint. OCI does not reliably apply a later IP change to an existing ADB; to keep 1.1.0-to-1.2.0 upgrades convergent, the module retains the OCI-assigned IP of an existing endpoint. Select the required IP when creating a new ADB.
7. Standalone CDB `database.backup_tde_password` is now sensitive. It is a `DB_BACKUP` creation-time credential and is not reapplied to an existing CDB.
8. In 1.1.0, the four advanced fields listed above were accepted inside `default_maintenance_window` but silently discarded. In 1.2.0, an existing infrastructure whose unchanged configuration already contains those fields can show an in-place maintenance-window update that applies the declared values. Review that update before applying; configurations that omit the fields do not receive new defaults.
9. Logical-key resolution through `kms_dependency` and `recovery_service_dependency` applies to new standalone CDBs declared in `databases_configuration`. The deprecated inline `cloud_db_homes_configuration[*].database` path is retained unchanged for zero-touch 1.1.0 upgrades and continues to require literal OCIDs for its nested `kms_key_id` and `dbrs_policy_id` values.

# Jan 29, 2026 Release Notes - 1.1.0
### Module Added
1. Added Autonomous Database Module

## Dec 1, 2025 Release Notes - 1.0.1
### Updates 
1. Restructured Folders to accommodate for Autonomous Database
2. Updated documentation
3. Added password validation for all exadata resources.
4. Update template files to remove unused variables.

### Fixes 
1. Fix regex matching in exadata-database/pluggable_database to allow matching *ocid1.dbhome*.

## October 23, 2025 Release Notes - 1.0.0
1. Initial release of Exadata Database Service Module designed to be used with OCI Landing Zones blueprints.
This repository includes the modules and examples to deploy Exadata Database Service on Dedicated Infrastructure on OCI.

## October 7, 2025 Release Notes - 0.1.0
1. Early Preview of Exadata Module.

This repository contains Terraform OCI (Oracle Cloud Infrastructure) modules for resources that help customers deploy and manage Exadata Database Service on Dedicated Infrastructure on OCI.

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Licensed under the Universal Permissive License (UPL), Version 1.0.

See [LICENSE](./LICENSE.txt) for more details.
