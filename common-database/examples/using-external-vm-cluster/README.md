# Common Database with an External VM Cluster

This example shows the composition boundary of the module: the Cloud VM Cluster is created elsewhere and handed in through `vm_cluster_dependency`; this module owns only the DB Home, CDB, and PDB resources.

Supply configuration in a `.tfvars` file, then run `terraform init`, `terraform plan`, and `terraform apply` from this directory.
