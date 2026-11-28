# Deploy a Serverless Autonomous Database with an existing encryption key

Supply the OCIDs of an existing Vault and its TDE key in `vaults_dependency` and `kms_dependency`. The plan should create one Serverless database, a dynamic group, and its policy. It should reuse the supplied Vault and key.

Supply the administrator password secret OCID in `secrets_dependency`. The principal running Terraform must be able to read its current version.

The module names the group `<db_name>-dynamic-group` and the policy `<db_name>-policy`. Membership covers resource principals in the database compartment. The policy limits access to the specified Vault and TDE key.

See the [input template](./input.auto.tfvars.template) and the [module configuration reference](../../SPEC.md).

## Using this example

1. Copy `input.auto.tfvars.template` to `input.auto.tfvars` in this directory.
2. Set the tenancy OCID, region, and authentication values in your copy. Uncomment the corresponding assignments if needed. Replace the resource placeholders with values for your deployment. See [OCI provider authentication](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare).
3. From this directory, generate a plan and compare it with the resources described above.

   ```shell
   terraform init
   terraform plan -out=plan.out
   ```

4. If the proposed actions and target resources are correct, apply the reviewed plan with `terraform apply plan.out`. Restrict access to saved plans and state files, which can contain credentials.
