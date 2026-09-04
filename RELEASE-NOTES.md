# September 4, 2026 Release Notes - 1.2.0

## Updates
1. Added Exadata Database dependency output for OCI Landing Zones Orchestrator consumption.
2. Added cross-stack Exadata Database dependency support for Exadata infrastructures, VM clusters, DB homes, databases, and pluggable databases.
3. Added KMS dependency support for Exadata Database encryption key references.
4. Added external PDB lookup support for PDB clone source references.
5. Fixed optional customer contacts, VM cluster compartment fallback, defined tags defaulting, CDB defined tags drift, null DB server lists, VM cluster subscription lookup, nested database KMS lookup, PDB password sensitivity handling, and sensitive raw database outputs.
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
16. Added the Autonomous Recovery Service module for recovery service subnets, protection policies, and protected databases, with optional NSGs and IAM policy creation. Exadata Database supports DBRS handoff through `recovery_service_dependency`.
17. Added Exadata Database protection policy resolution for direct and wrapped dependency maps, literal OCID passthrough, standalone database integration, and explicit rejection of unresolved protection policy keys.
18. Added logical-key dependencies for externally managed VM clusters and DB systems.
19. Marked standalone CDB backup TDE passwords as sensitive and ignored OCI provenance tags without suppressing customer tag management.

## Upgrade from 1.1.0

1. Existing Exadata Database and Autonomous Database 1.1.0 configurations remain accepted in 1.2.0. For a version-only upgrade, update the module version, retain the existing configuration, and review the first plan before applying. Investigate any unexpected creation, replacement, or destruction of existing resources. See [Updating from 1.1.0](./exadata-database/README.md#updating-from-110).
2. Existing Exadata Database 1.1.0 CDB configurations remain accepted. New CDBs use `databases_configuration` and reference a DB Home by key or OCID.
3. Existing ADB Shared / Serverless TDE configurations can retain Vault OCIDs in `kms_dependency`. For new TDE configurations, use `vaults_dependency` for Vault logical keys and keep encryption keys in `kms_dependency`.
4. Exadata Database raw outputs `database_homes`, `databases`, and `pluggable_databases` are now sensitive. Root modules that re-export them should mark their own outputs as `sensitive = true` or use `exadata_database_resources` for dependency handoff.
5. Exadata Database validates standalone CDB/PDB inputs earlier, including CDB names with special characters, `OBJECT_STORAGE` backup destination spelling, unsupported standalone source encryption fields, and DB Home OCIDs used as PDB container database IDs.
6. Due to a 1.1.0 bug, `networking.private_endpoint_ip` was accepted but was not passed to OCI. In 1.2.0, the value is passed when creating a new ADB Shared / Serverless private endpoint. OCI does not reliably apply a later IP change to an existing ADB; to keep 1.1.0-to-1.2.0 upgrades convergent, the module retains the OCI-assigned IP of an existing endpoint. Select the required IP when creating a new ADB.
7. Standalone CDB `database.backup_tde_password` is now sensitive. It is a `DB_BACKUP` creation-time credential and is not reapplied to an existing CDB.

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
