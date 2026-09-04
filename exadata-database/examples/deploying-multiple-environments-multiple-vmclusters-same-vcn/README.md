# OCI Landing Zones Exadata Module Example - Multiple Environments and VM Clusters with the same VCN

## Introduction
This example shows how to deploy multiple Exadata VM Clusters in the same VCN but different subnets in Oracle Cloud Infrastructure (OCI).

It deploys the following resources:
- one Exadata Infrastructure
  - one VM Cluster in subnet-1
  - one VM cluster in subnet-2

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
