# OCI Landing Zones Base Database Service Example - Simple

## Introduction

This is an example of deploying a single-node Base Database Service DB System.

Prerequisites that need to be manually configured:

1. An OCI tenancy and compartment where the DB System will be deployed
2. A client subnet for the DB System
3. An OCI API signing key for Terraform authentication
4. An SSH public key for DB System access

## Resources Deployed

This example deploys the following resources:

1. A single-node Base Database Service DB System
2. An inline Database Home and database
3. The initial PDB configured for the database

## Configuration and Usage

See [input.auto.tfvars.template](./input.auto.tfvars.template) for resource configuration.
See [Module's README.md](../../README.md) for overall attribute usage.

## Using this example

1. Rename *input.auto.tfvars.template* to *\<project-name\>.auto.tfvars*.
2. Within *\<project-name\>.auto.tfvars*, provide tenancy connectivity information and update the example OCIDs, API key values, SSH public key, database version, and administrator password.

   Follow [this guide](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare) to gather the required OCI provider information.

3. In this folder, run the typical Terraform workflow:

```text
terraform init
terraform plan -out plan.out
terraform apply plan.out
```
