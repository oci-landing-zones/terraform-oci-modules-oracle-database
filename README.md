# OCI Landing Zones Database Modules
![Landing_Zone_Logo](./landing_zone_300.png)

## Table of Contents

1. [Overview](#overview)
1. [OCI Landing Zones Modules Collection](#modules-collection)
1. [Contributing](#contributing)
1. [License](#license)
1. [Known Issues](#known-issues)


## <a name="overview">Overview</a>
This repository contains Terraform OCI (Oracle Cloud Infrastructure) modules for deploying and managing Database services on OCI.

Modules included in this repository:
1. Exadata Database Services. [See more details](./exadata-database/README.md)
2. Common Database resources (Database Homes, container databases, and pluggable databases). [See more details](./common-database/README.md)
3. Autonomous Database Services. [See more details](./autonomous-database/README.md)
4. Autonomous Recovery Service. [See more details](./autonomous-recovery-service/README.md)
5. Exadata Database Service on Exascale Infrastructure (ExaDB-XS). [See more details](./exadb-xs/README.md)
6. Exascale DB Storage Vaults. [See more details](./exascale-db-storage-vault/README.md)


## <a name="modules-collection">OCI Landing Zones Modules Collection</a>
This repository is part of a broader collection of repositories containing modules that help customers align their OCI implementations with the CIS OCI Foundations Benchmark recommendations:
- [Oracle Database modules](https://github.com/oci-landing-zones/terraform-oci-modules-oracle-database) - current repository
- [Identity & Access Management](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-iam)
- [Networking](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-networking)
- [Governance](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-governance)
- [Security](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-security)
- [Observability & Monitoring](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-observability)
- [Secure Workloads](https://github.com/oracle-quickstart/terraform-oci-secure-workloads)

The modules in this collection are designed for flexibility, are straightforward to use, and enforce CIS OCI Foundations Benchmark recommendations when possible.

Using these modules does not require a user extensive knowledge of Terraform or OCI resource types usage. Users declare a JSON object describing the OCI resources according to each module’s specification and minimal Terraform code to invoke the modules. The modules generate outputs that can be consumed by other modules as inputs, allowing for the creation of independently managed operational stacks to automate your entire OCI infrastructure.

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process.

## License

Copyright (c) 2025 Oracle and/or its affiliates.

*Replace this statement if your project is not licensed under the UPL*

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.

## Known Issues

- ExaDB-XS validation cannot establish live OCI service capacity, quota or policy
  availability; nor can it prove supported Grid Image/shape combinations or the
  storage-mode compatibility of an existing vault. Those behaviours require an
  approved OCI test tenancy.
- The Exadata Dedicated Infrastructure wrapper can create and publish an
  Exascale DB Storage Vault, but it does not yet attach that vault to an
  existing Cloud VM Cluster. The OCI service/provider contract for that
  attachment still requires confirmation.
- Exadata-D provisioning can require a retry when dependent resources are
  still updating, and a deployment can run for many hours. See the
  [Exadata-D known issues](./exadata-database/README.md#known-issues).
