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

Choose the module that owns the resources you want to manage.

1. [Exadata Database](./exadata-database/README.md) manages Exadata infrastructure, Cloud VM Clusters, DB Homes, CDBs, and PDBs. It can also use existing infrastructure or clusters.
2. [Common Database](./common-database/README.md) manages DB Homes, CDBs, and PDBs independently of the host infrastructure.
3. [Autonomous Database](./autonomous-database/README.md) provisions Serverless databases and Dedicated databases in an existing Autonomous Container Database.
4. [Autonomous Recovery Service](./autonomous-recovery-service/README.md)
5. [Base Database Service](./base-database/README.md)

For an existing deployment, review the [1.3.1 upgrade instructions](./RELEASE-NOTES.md#upgrading-to-131) before changing the module version or enabling external CPU management.

## <a name="modules-collection">OCI Landing Zones Modules Collection</a>
This repository is part of a broader collection of repositories containing modules that help customers align their OCI implementations with the CIS OCI Foundations Benchmark recommendations:
- [Identity & Access Management](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-iam)
- [Networking](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-networking)
- [Governance](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-governance)
- [Security](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-security)
- [Observability & Monitoring](https://github.com/oracle-quickstart/terraform-oci-cis-landing-zone-observability)
- [Secure Workloads](https://github.com/oracle-quickstart/terraform-oci-secure-workloads)

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process.

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.

## Known Issues

See the [release notes](./RELEASE-NOTES.md) for upgrade guidance and known limitations.
