# OCI Landing Zones Exadata Module Example - Quickstart Deployment

## Introduction
This example shows a quick start example of how to deploy Exadata resources in Oracle Cloud Infrastructure (OCI).

It deploys the following resources:
- one Exadata Infrastructure
  - one VM cluster
    - one Database Home
      - one Container Database
        - two Pluggable Databases

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
