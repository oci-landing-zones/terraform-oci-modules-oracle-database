# Deploy a Serverless Autonomous Database with existing Landing Zone IAM and encryption

Supply the OCIDs of the existing Vault and TDE key. The Landing Zone dynamic group and policy must already allow the database to use that key. The plan should create one Serverless database and reuse the existing key, dynamic group, and policy.

In a Core Landing Zone these resources typically include the `<service-label>-database-kms-dynamic-group`, its `<service-label>-database-dynamic-group-policy`, and the `<service-label>-vault`. The example selects the Vault and key by OCID.

Supply the administrator password secret OCID in `secrets_dependency`. The principal running Terraform must be able to read its current version.

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
