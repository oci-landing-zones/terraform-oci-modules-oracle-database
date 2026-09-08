# Exadata Database Service on Dedicated Infrastructure with Autonomous Recovery Service

This example creates Autonomous Recovery Service resources in the VCN used by an existing Exadata Database Service on Dedicated Infrastructure VM cluster, then configures a CDB backup destination to use Recovery Service.

The example provisions:

- A Recovery Service subnet registration for the VM cluster VCN.
- A custom Recovery Service protection policy.
- A CDB in an existing Exadata DB home using the `exadata-database` module.
- A CDB with `db_backup_config.backup_destination_details.type = "DBRS"` and `dbrs_policy_id` set to an ARS protection policy key. The Exadata module resolves the key through `recovery_service_dependency`.

## Usage

1. Copy `input.auto.tfvars.template` to a `.auto.tfvars` file.
2. Replace the placeholder OCIDs and credentials.
3. Run `terraform init`, `terraform plan`, and `terraform apply`.
