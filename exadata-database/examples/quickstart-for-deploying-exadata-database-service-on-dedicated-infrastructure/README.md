# Create an Exadata database deployment on new dedicated infrastructure

The plan should create one Exadata infrastructure, one VM Cluster, one DB Home, and one CDB. The initial PDB is part of CDB creation. The second PDB appears as a separate Terraform resource.

See the [input template](./input.auto.tfvars.template) and the [module configuration reference](../../SPEC.md).

## Using this example

1. Copy `input.auto.tfvars.template` to `input.auto.tfvars` in this directory.
2. Set the tenancy OCID, region, and authentication values in your copy. Uncomment the corresponding assignments if needed. Replace the resource placeholders with values for your deployment. The Terraform principal needs read access to the current password secret versions. See [OCI provider authentication](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-provider.htm#prepare).
3. From this directory, generate a plan and compare it with the resources described above.

   ```shell
   terraform init
   terraform plan -out=plan.out
   ```

4. If the proposed actions and target resources are correct, apply the reviewed plan with `terraform apply plan.out`. Restrict access to saved plans and state files, which can contain credentials.
