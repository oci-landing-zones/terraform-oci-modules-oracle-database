# ExaDB-XS quickstart

Copy `input.auto.tfvars.template` to `input.auto.tfvars`, replace every example
value with a value valid for the target tenancy and availability domain, then run
`terraform init` and `terraform plan`. This example creates one storage vault and
one ExaDB-XS VM cluster. Add `cloud_db_homes_configuration` when a Database Home,
Container Database, or Pluggable Database is required.
