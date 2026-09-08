# OCI Landing Zones Exadata Module Example - Multiple Environments and VM Clusters with Different VCNs, DB Homes, Container Databases, and Pluggable Databases

## Introduction
This example shows how to deploy Exadata resources in Oracle Cloud Infrastructure (OCI).

It deploys the following resources:
- one Exadata Infrastructure
  - VM Cluster-1 in VCN-1
    - DB Home-1 
      - Container Database-1
        - Pluggable Database-1
        - Pluggable Database-2
      - Container Database-2
        - Pluggable Database-3
        - Pluggable Database-4
    - DB Home-2
      - Container Database-3
        - Pluggable Database-5
        - Pluggable Database-6
      - Container Database-4
        - Pluggable Database-7
        - Pluggable Database-8
  - VM Cluster-2 in VCN-2

See [input.auto.tfvars.template](./input.auto.tfvars.template) for resource configuration.
See [Module's README.md](../../README.md) for overall attributes usage.

## Using this example
1. Rename *input.auto.tfvars.template* to *\<project-name\>.auto.tfvars*, where *\<project-name\>* is any name of your choice. 
2. Within *\<project-name\>.auto.tfvars*, provide tenancy connectivity information and adjust the input variables marked with *<REPLACE-WITH-...>*.

   Follow [this guide](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare) to gather required information.

3. In this folder, run the typical Terraform workflow:
```
terraform init
terraform plan -out plan.out
terraform apply plan.out
```
