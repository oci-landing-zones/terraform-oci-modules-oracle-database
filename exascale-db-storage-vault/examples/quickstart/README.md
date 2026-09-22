# Exascale DB Storage Vault quickstart

Copy `input.auto.tfvars.template` to `input.auto.tfvars`, replace every
`replace-me` value with target-tenancy values, and run:

```text
terraform init
terraform plan
```

This example creates one independent Exascale DB Storage Vault. It does not
create a VM Cluster or connect the vault to a consumer.
