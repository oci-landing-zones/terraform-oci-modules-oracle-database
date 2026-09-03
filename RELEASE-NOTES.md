# Database Modules Release Notes
# Unreleased
### Updates
1. Added the reusable `common-database` module for Database Homes, container databases, and pluggable databases.
2. Refactored `exadata-database` to compose `common-database` while preserving its existing input and output contract.
3. Added Terraform moved declarations so existing DB Home, database, and PDB state addresses migrate into the child module without resource recreation.
4. Added logical-key dependencies for externally managed VM clusters and DB systems to support composition with Exadata and other database infrastructure modules.

# Jul 7, 2026 Release Notes - 1.2.0
> Upgrade guidance: 1.1.0 configurations remain accepted in 1.2.0, including the deprecated DB Home inline database path, but should review the compatibility impacts and recommended migration steps below before applying. New configurations should use the 1.2.0 contracts directly.

### Compatibility Notes from 1.1.0
1. Exadata Database keeps the 1.1.0 DB Home inline database contract as a deprecated direct-module compatibility path. The module normalizes it into standalone CDB resources; new configurations should use `databases_configuration` and reference a DB Home by key or OCID.
2. Autonomous Database Shared / Serverless TDE vault logical keys now resolve through `vaults_dependency`. A temporary 1.1.0 compatibility fallback accepts vault OCIDs stored in `kms_dependency`, but this fallback is deprecated and should not be used for new configurations.
3. Exadata Database raw outputs `database_homes`, `databases`, and `pluggable_databases` are now sensitive. Root modules that re-export them should mark their own outputs as `sensitive = true` or use `exadata_database_resources` for dependency handoff.
4. Exadata Database validates CDB/PDB inputs earlier, including CDB names with special characters, `OBJECT_STORAGE` backup destination spelling, unsupported source encryption fields, and DB Home OCIDs used as PDB container database IDs.
5. The first upgrade plan can show expected differences where 1.2.0 now wires previously ignored fields or applies default tags/private endpoint IP/TDE wallet defaults. Review the plan before applying.

### Migration Steps from 1.1.0
1. A CDB configured inline under `cloud_db_homes_configuration[*].database` remains accepted and normalized in 1.2.0, but migrate it to `databases_configuration` with `db_home_id` set to the DB Home key or OCID when updating the configuration.
2. If ADB Shared / Serverless TDE used a vault key in `kms_dependency`, move the vault object to `vaults_dependency` and keep encryption keys in `kms_dependency`.
3. If a root module exposes Exadata raw outputs, either mark those outputs as sensitive or switch downstream consumers to `exadata_database_resources`.
4. Before applying 1.2.0, run a clean plan on 1.1.0, update the module source, run another plan, and review DB Home, CDB, PDB, ADB private endpoint, tag, and sensitive output changes.

### Updates
1. Added Exadata Database dependency output for OCI Landing Zones Orchestrator consumption.
2. Added cross-stack Exadata Database dependency support for Exadata infrastructures, VM clusters, DB homes, databases, and pluggable databases.
3. Added KMS dependency support for Exadata Database encryption key references.
4. Added external PDB lookup support for PDB clone source references.
5. Fixed optional customer contacts, VM cluster compartment fallback, defined tags defaulting, CDB defined tags drift, null DB server lists, VM cluster subscription lookup, nested database KMS lookup, PDB password sensitivity handling, and sensitive raw database outputs.
6. Added Autonomous Database dependency output for OCI Landing Zones Orchestrator consumption.
7. Added vault dependency support for Autonomous Database TDE vault references.
8. Updated the Autonomous Database provider alias declaration for Orchestrator module invocation.
9. Fixed Autonomous Database private endpoint IP pass-through.
10. Deprecated the DB Home inline database contract and normalized it into standalone Container Database resources. New configurations use `databases_configuration` so downstream outputs remain normalized for multi-stack handoff.
11. Aligned Exadata Database Terraform version requirements with the Orchestrator and Autonomous Database modules.
12. Added Autonomous Database module specification and refreshed examples for ADB Shared / Serverless and ADB Dedicated usage.
13. Fixed Autonomous Database Dedicated handling so serverless TDE vault/key data sources are not read when TDE is inherited from an existing Autonomous Container Database.
14. Added Exadata X11MV support for infrastructure shape `Exadata.X11MV`, database server type `X11MV`, and storage server type `X11MV-HC`.
15. Made the fallback Exadata Availability Domain selection deterministic when `availability_domain` is omitted and rejected unsupported `azure_encryption_key_id` values in the deprecated legacy inline source-encryption path.
16. Added the Autonomous Recovery Service module for recovery service subnets and protection policies, with Exadata Database DBRS handoff through `recovery_service_dependency`.
17. Added Exadata Database protection policy resolution for direct and wrapped dependency maps, literal OCID passthrough, legacy inline database normalization, and explicit rejection of unresolved protection policy keys.

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
