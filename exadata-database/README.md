# OCI Landing Zones Exadata Module
![Landing_Zone_Logo](../landing_zone_300.png)

## Table of Contents

1. [Overview](#overview)
1. [Getting Started](#getting-started)
1. [Pre-requisites](#Pre-requisites)
1. [Module Inputs](#module-inputs)
1. [Cloud Exadata Infrastructures](#cloud-exadata-infrastructures)    
1. [Cloud VM Clusters](#cloud-vm-clusters)
1. [Cloud DB Homes](#cloud-db-homes)
1. [Databases](#databases)
1. [Pluggable Databases](#pluggable-databases)
1. [Outputs](#outputs)
1. [Updating from 1.1.0](#updating-from-110)
1. [OCI Landing Zones Modules Collection](#modules-collection)
1. [Contributing](#contributing)
1. [License](#license)
1. [Known Issues](#known-issues)


## <a name="overview">Overview</a>
This repository contains Terraform OCI (Oracle Cloud Infrastructure) modules for resources that help customers deploy and manage Exadata Database Service on Dedicated Infrastructure on OCI.

The following resources are available:

- Exadata Infrastructure
- VM Clusters
- Database Home
- Container Database
- Pluggable Database

## Getting Started

For a new deployment, start with the [Exadata quickstart](./examples/quickstart-for-deploying-exadata-database-service-on-dedicated-infrastructure/README.md). Additional examples cover [existing VM Clusters with DB Homes, CDBs, and PDBs](./examples/creating-additional-dbhomes-with-multiple-cdb-pdb/README.md) and multi-environment deployments.

Use the released module source in a root module:

```hcl
module "exadata_database" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-exadata//exadata-database?ref=v1.2.0"

  # Configure the inputs required by the selected deployment pattern.
}
```

The complete input and output contract is in [SPEC.md](./SPEC.md).

This module supports being passed an object containing references to OCIDs (Oracle Cloud IDs) that they may depend on. Every input attribute that expects an OCID (typically, attribute names ending in _id or _ids) can be given either a literal OCID or a reference (a key) to the OCID. While these OCIDs can be literally obtained from their sources and pasted when setting the modules input attributes, a superior approach is automatically consuming the outputs of producing modules. For instance, the Exadata Infrastructure module may depend on compartments and networks for deployment. It can be passed a compartments_dependency map and a network_dependency map with objects representing compartments and networks produced by other modules. The external dependency approach helps with the creation of loosely coupled Terraform configurations with clearly defined dependencies between them, avoiding copying and pasting OCIDs.

## <a name="Pre-requisites">Pre-requisites</a>

Before deploying the Exadata Cloud Infrastructure, VM Cluster, Database Home, Database, and PDB resources, ensure the following prerequisites are met:

- [**IAM Policies**](https://docs.oracle.com/en-us/iaas/exadatacloud/doc/ecs-policy-details.html)  
  Ensure you have access to an active OCI Tenancy with sufficient permissions to create networking and database resources.

- [**Create RSA keys**](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare)  
  Follow [this guide](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare) to Create RSA keys.

- [**Virtual Cloud Network (VCN)**](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/create_vcn.htm#top)  
  A VCN must be created in the target region where the Exadata Infrastructure will reside. 
  You can create the VCN and associated subnets in one of the following ways:

  1. **Using the OCI Core Landing Zone Template**  
     Visit the [OCI Core Landing Zone GitHub repository](https://github.com/oci-landing-zones/terraform-oci-core-landingzone/tree/main/templates/standalone-three-tier-vcn-custom).  
     - Scroll down to the **“Deploy to Oracle Cloud”** section.  
     - Click **Deploy to Oracle Cloud** to launch Resource Manager (RMS).  
     - In the RMS stack, select **Exadata VCN** to deploy the VCN configuration suitable for Exadata environments.

  2. **Using the OCI Console**  
     Follow the [VCN creation guide](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/create_vcn.htm#top) to manually create the network components.

- [**Subnets**](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/create_subnet.htm#top)  
  You must have at least two subnets available for Exadata infrastructure and VM clusters:
  - **Client Subnet:** For database client connections  
  - **Backup Subnet:** For Object Storage and backup operations  

  Subnets can be:
  - Private (recommended for Exadata)  
  - Created in the same Availability Domain as the Exadata infrastructure  

  Each subnet must have:
  - A valid Route Table  
  - Security Lists or Network Security Groups (NSGs) configured for required ingress/egress

- [**Route Tables and Gateways**](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/managingroutetables.htm)  
  Ensure that the subnet attached to the Exadata infrastructure can reach OCI Object Storage, required for backups and wallet access.  

  You can configure this using either:
  - [A **Service Gateway**](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/servicegateway.htm) — for private subnet access to Object Storage, or  
  - [An **Internet Gateway**](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/managingIGs.htm) — if using a public subnet.

## <a name="module-inputs">Module Inputs</a>
The module accepts the following input variables:

### General
- module_name: The module name. Defaults to "exadata-cloud-service".
- enable_output: Whether Terraform should enable module output. Defaults to true.
- compartments_dependency: A map of objects containing the externally managed compartments this module may depend on.
- subscription_dependency: A map of objects containing externally managed subscriptions this module may depend on.
- exadata_database_dependency: An object containing externally managed Exadata Database resources this module may depend on.
- kms_dependency: A map of objects containing externally managed encryption keys this module may depend on.
- network_dependency: A map of objects containing the externally managed network resources this module may depend on.
- recovery_service_dependency: A map of externally managed Autonomous Recovery Service protection policies this module may depend on. Pass either the ARS module `protection_policies` output directly, or an object containing a `protection_policies` map.
- default_compartment_id: Default Compartment ID for all resources.
- default_defined_tags: Default defined tags for all resources.
- default_freeform_tags: Default freeform tags for all resources.

### External Dependencies
The `exadata_database_dependency` input enables multi-stack deployments where Exadata infrastructure, VM clusters, DB homes, databases, or pluggable databases are created in a previous stack and referenced by logical key in a later stack. It accepts the same shape produced by the `exadata_database_resources` output:

- cloud_exadata_infrastructures
- cloud_vm_clusters
- database_homes
- databases
- pluggable_databases

Each map preserves the logical keys used by the producing stack and exposes at least the resource `id`. Compartment-scoped resources also expose `compartment_id` when available.
For PDB clone operations, `pdb_creation_type_details.source_pluggable_database_id` may reference a logical key from `exadata_database_dependency.pluggable_databases`.

### <a name="cloud-exadata-infrastructures">Cloud Exadata Infrastructures</a>
- cloud_exadata_infrastructures_configuration: Exadata infrastructure configuration. This is an object with the following attributes:
  - default_maintenance_window: Default maintenance window configuration.
  - cloud_exadata_infrastructures: A map of Exadata infrastructure configurations.

Each Exadata infrastructure configuration object has the following attributes:

- display_name: Display name of the Exadata infrastructure.
- shape: Shape of the Exadata infrastructure. Accepted values are Exadata.X11MV, Exadata.X11M, Exadata.X9M, and Exadata.X8M.
- compartment_id: Compartment ID of the Exadata infrastructure. Overrides default compartment ID.
- availability_domain: Availability domain of the Exadata infrastructure. When omitted, the module selects the lexicographically first name from the availability domains discovered for the resolved compartment.
- compute_count: Compute count of the Exadata infrastructure.
- customer_contacts: Customer contact information.
- database_server_type: Database server type. Accepted values are X11MV, X11M-BASE, X11M, X11M-L, and X11M-XL.
- defined_tags: Defined tags for the Exadata infrastructure.
- freeform_tags: Freeform tags for the Exadata infrastructure.
- maintenance_window: Maintenance window configuration.
- storage_count: Storage count of the Exadata infrastructure.
- storage_server_type: Storage server type. Accepted values are X11MV-HC, X11M-BASE, and X11M-HC.
- subscription_id: Subscription ID of the Exadata infrastructure.

For more details on this resource, please see OCI Terraform Documentation for [oci_database_cloud_exadata_infrastructure](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_cloud_exadata_infrastructure)


### <a name="cloud-vm-clusters">Cloud VM Clusters</a>
- cloud_vm_clusters_configuration: OCI Database Cloud Exadata VM Cluster Configuration. This is a map of VM cluster configurations.

Each Cloud VM cluster configuration object has the following attributes:
- backup_subnet_id: Backup subnet ID of the VM cluster.
- exadata_infrastructure_id: Exadata infrastructure ID of the VM cluster.
- compartment_id: Compartment ID of the VM cluster. Overrides default compartment ID.
- cpu_core_count: CPU core count of the VM cluster.
- display_name: Display name of the VM cluster.
- gi_version: GI version of the VM cluster.
- hostname: Hostname of the VM cluster.
- ssh_public_keys: SSH public keys for the VM cluster.
- subnet_id: Subnet ID of the VM cluster.
backup_network_nsg_ids: Backup network NSG IDs of the VM cluster.
- cloud_automation_update_details: Cloud automation update details for the VM cluster.
- cluster_name: Cluster name of the VM cluster.
- data_collection_options: Data collection options for the VM cluster.
- data_storage_percentage: Data storage percentage of the VM cluster.
- data_storage_size_in_tbs: Data storage size in TBs of the VM cluster.
- db_node_storage_size_in_gbs: DB node storage size in GBs of the VM cluster.
- db_servers: DB servers of the VM cluster.
- defined_tags: Defined tags for the VM cluster.
- freeform_tags: Freeform tags for the VM cluster.
- domain: Domain of the VM cluster.
- file_system_configuration_details: File system configuration details for the VM cluster.
- is_local_backup_enabled: Whether local backup is enabled for the VM cluster.
- is_sparse_diskgroup_enabled: Whether sparse diskgroup is enabled for the VM cluster.
- license_model: License model of the VM cluster.
- memory_size_in_gbs: Memory size in GBs of the VM cluster.
- nsg_ids: NSG IDs of the VM cluster.
- ocpu_count: OCPU count of the VM cluster.
- private_zone_id: Private zone ID of the VM cluster.
- scan_listener_port_tcp: Scan listener port TCP of the VM cluster.
- scan_listener_port_tcp_ssl: Scan listener port TCP SSL of the VM cluster.
- security: Security attributes for the VM cluster.
- subscription_id: Subscription ID of the VM cluster.
- system_version: System version of the VM cluster.
- time_zone: Time zone of the VM cluster.
- vm_cluster_type: VM cluster type.

These attributes are not updatable after initial resource creation:
- gi_version
- system_version
- defined_tags

For more details on this resource, please see OCI Terraform Documentation for [oci_database_cloud_vm_cluster](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_cloud_vm_cluster)


### <a name="cloud-db-homes">Cloud DB Homes</a>
- cloud_db_homes_configuration: OCI Database Cloud Database Home Configuration. This is a map of DB Home configurations.

Each DB Home object has the following attributes:
- database_software_image_id: The database software image OCID
- db_system_id: The OCID of the DB system.
- db_version: A valid Oracle Database version. For a list of supported versions, use the ListDbVersions operation.
- defined_tags: Defined tags for this resource. Each key is predefined and scoped to a namespace. For more information, see Resource Tags.
- display_name: The user-provided name of the Database Home.
- is_desupported_version: If true, the customer acknowledges that the specified Oracle Database software is an older release that is not currently supported by OCI.
- is_unified_auditing_enabled: Indicates whether unified autiding is enabled or not. Set to True to enable unified auditing on respective DBHome.
- kms_key_id: The OCID of the key container that is used as the master encryption key in database transparent data encryption (TDE) operations.
- kms_key_version_id: The OCID of the key container version that is used in database transparent data encryption (TDE) operations KMS Key can have multiple key versions. If none is specified, the current key version (latest) of the Key Id is used for the operation.
- freeform_tags: Free-form tags for this resource. Each tag is a simple key-value pair with no predefined name, type, or namespace. For more information, see Resource Tags. Example: {"Department": "Finance"}
- source: The source of database: NONE for creating a new database. DB_BACKUP for creating a new database by restoring from a database backup. VM_CLUSTER_NEW for creating a database for VM Cluster.
- vm_cluster_id: The OCID or key of the VM cluster.

New Container Databases are created with `databases_configuration`, referencing the DB Home by key or OCID. This standalone contract is the supported path for new same-stack and multi-stack deployments.

#### Updating from 1.1.0

Existing Exadata Database callers can upgrade to 1.2.0 while retaining their existing module configuration. For a version-only upgrade, run and review the first plan before applying it, and investigate any unexpected creation, replacement, or destruction of existing Exadata resources.

These attributes are not updatable after initial resource creation
- db_version
- database_software_image_id

For more details on this resource, please see OCI Terraform Documentation for [oci_database_db_home](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_db_home)


### <a name="databases">Databases</a>
- databases_configuration: OCI Container Database Configuration. This is a map of database configurations. 

Each Database Configuration object has the following attributes:
- database: Details for creating a database.
- Optional attribute `database.tde_wallet_password` passes the TDE wallet password for database creation or restore flows when OCI requires it. If omitted, the module passes null and does not default it from `database.admin_password`.
- db_home_id: The OCID or key of the Database Home.
- source: The source of the database: Use NONE for creating a new database. Use DB_BACKUP for creating a new database by restoring from a backup. Use DATAGUARD for creating a new STANDBY database for a Data Guard setup. The default is NONE.
- key_store_id: The OCID of the key store of Oracle Vault.
- db_version: A valid Oracle Database version. For a list of supported versions, use the ListDbVersions operation.
- kms_key_id: The OCID of the key container that is used as the master encryption key in database transparent data encryption (TDE) operations.
- kms_key_version_id: The OCID of the key container version that is used in database transparent data encryption (TDE) operations KMS Key can have multiple key versions. If none is specified, the current key version (latest) of the Key Id is used for the operation.
- database.db_backup_config.backup_destination_details.dbrs_policy_id: The Autonomous Recovery Service protection policy OCID, or a key in `recovery_service_dependency`.

These attributes are not updatable after initial resource creation:
- db_home_id
- db_version
- database.admin_password

For more details on this resource, please see OCI Terraform Documentation for [oci_database_database](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/7.20.0/docs/r/database_database.html)

### <a name="pluggable-databases">Pluggable Databases</a>
- pluggable_databases_configuration: OCI Pluggable Database Configuration. This is a map of PDB configurations.

Each PDB Configuration object has the following attributes:
- container_database_id: The OCID or key of the CDB.
- pdb_name: The name for the pluggable database (PDB). The name is unique in the context of a container database. The name must begin with an alphabetic character and can contain a maximum of thirty alphanumeric characters. Special characters are not permitted. The pluggable database name should not be same as the container database name.
- container_database_admin_password: The DB system administrator password of the Container Database.
- defined_tags: Defined tags for this resource. Each key is predefined and scoped to a namespace.
- freeform_tags: Free-form tags for this resource. Each tag is a simple key-value pair with no predefined name, type, or namespace.
- kms_key_version_id: OCID of the Master Encryption Key Version, if using Key Management Service (KMS) key rotation. 
- pdb_admin_password:  A strong password for PDB Admin. The password must be at least nine characters and contain at least two uppercase, two lowercase, two numbers, and two special characters. The special characters must be _, #, or -.
- pdb_creation_type_details: The Pluggable Database creation type. [See details](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_pluggable_database#pdb_creation_type_details-2)
- should_create_pdb_backup: Indicates whether to take Pluggable Database Backup after the operation.
- should_pdb_admin_account_be_locked: The locked mode of the pluggable database admin account. If false, the user needs to provide the PDB Admin Password to connect to it. If true, the pluggable database will be locked and user cannot login to it.
- tde_wallet_password: The existing TDE wallet password of the CDB.

## Outputs
The module keeps the raw resource outputs for direct module compatibility and also publishes `cloud_exadata_database_resources` for downstream dependency consumption. Raw DB Home, database, and pluggable database outputs are sensitive because they can include password-backed attributes. The `cloud_exadata_database_resources` output contains minimal maps for Exadata infrastructures, VM clusters, DB homes, databases, and pluggable databases.

The canonical Cloud Exadata Database dependency output is `cloud_exadata_database_resources`. The `cloud_exadata_database_dependency` output exposes the same minimal shape for Orchestrator dependency consumption. The shorter `exadata_database_resources` and `exadata_database_dependency` outputs are aliases for integrations that still read the shorter Exadata names instead of falling back to raw resource outputs.


## <a name="modules-collection">OCI Landing Zones Modules Collection</a>
This repository is part of a broader collection of repositories containing modules that help customers deploy and manage various OCI resources:

- [Exadata](https://github.com/oci-landing-zones/terraform-oci-modules-exadata) - current repository
- [Identity & Access Management](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-iam)
- [Networking](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-networking)
- [Governance](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-governance)
- [Security](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-security)
- [Observability & Monitoring](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-observability)
- [Secure Workloads](https://github.com/oracle-quickstart/terraform-oci-secure-workloads)

The modules in this collection are designed for flexibility, are straightforward to use, and follow best practices.

Using these modules does not require a user extensive knowledge of Terraform or OCI resource types usage. Users declare a JSON object describing the OCI resources according to each module’s specification and minimal Terraform code to invoke the modules. The modules generate outputs that can be consumed by other modules as inputs, allowing for the creation of independently managed operational stacks to automate your entire OCI infrastructure.

## <a name="contributing">Contributing</a>
See [CONTRIBUTING.md](../CONTRIBUTING.md).

## <a name="license">License</a>
Copyright (c) 2025, Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

See [LICENSE](../LICENSE.txt) for more details.

## <a name="known-issues">Known Issues</a>
1.  The PDB creation might fail if the DB creation is in progress. solution: run "terraform apply" again and it will resume from where it left off.
2. When creating multiple Database Homes. in the same VM Cluster, this error may occur. "The operation cannot be performed because the Db System with ID ocid1... is in the UPDATING state." solution: run "terraform apply" again and it will resume from where it left off.
3. Each resource may take several hours to provision, so the terraform apply session may last 10+ hours. If terraform apply gets interrupted due to VPN disconnecting or other issues, run "terraform apply" again and it will resume from where it left off.
