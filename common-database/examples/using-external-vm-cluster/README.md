# Common Database with an External VM Cluster

This example creates a DB Home, a standalone CDB, and a PDB on an existing Cloud VM Cluster. Supply the VM Cluster OCID and its compartment through `vm_cluster_dependency`.

Save the following as `input.auto.tfvars`. Replace the placeholders with your OCIDs and choose a DB version supported on the cluster. The Terraform principal needs access to the current version of each password secret.

```hcl
vm_cluster_dependency = {
  existing = {
    id             = "<REPLACE-WITH-VM-CLUSTER-OCID>"
    compartment_id = "<REPLACE-WITH-DEFAULT-COMPARTMENT-OCID>"
  }
}

cloud_db_homes_configuration = {
  home = {
    vm_cluster_id = "existing"
    display_name  = "example-home"
    db_version    = "19.0.0.0"
  }
}

databases_configuration = {
  cdb = {
    db_home_id = "home"
    source     = "NONE"
    database = {
      db_name                  = "DEMODB"
      admin_password_secret_id = "<REPLACE-WITH-CDB1-ADMIN-PASSWORD-SECRET-OCID>"
    }
  }
}

pluggable_databases_configuration = {
  pdb = {
    container_database_id        = "cdb"
    pdb_name                     = "DEMOPDB"
    pdb_admin_password_secret_id = "<REPLACE-WITH-PDB1B-ADMIN-PASSWORD-SECRET-OCID>"
  }
}
```

With OCI authentication configured, run `terraform init` and `terraform plan` from this directory. The plan should create one DB Home, one CDB, and one PDB and leave the existing VM Cluster in place.
