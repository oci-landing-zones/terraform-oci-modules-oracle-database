mock_provider "oci" {
  override_resource {
    target          = module.exascale_db_storage_vault.oci_database_exascale_db_storage_vault.these["local"]
    override_during = plan
    values = {
      id = "ocid1.exascaledbstoragevault.oc1..local"
    }
  }
}

run "plans_dedicated_storage_vault_with_external_infrastructure" {
  command = plan

  variables {
    exadata_database_dependency = {
      cloud_exadata_infrastructures = {
        existing = {
          id             = "ocid1.cloudexadatainfrastructure.oc1..existing"
          compartment_id = "ocid1.compartment.oc1..database"
        }
      }
    }

    exascale_db_storage_vaults_configuration = {
      default_compartment_id = "ocid1.compartment.oc1..database"
      exascale_db_storage_vaults = {
        dedicated = {
          availability_domain                = "test:AD-1"
          display_name                       = "dedicated-exascale-vault"
          exadata_infrastructure_id          = "existing"
          high_capacity_database_storage_gbs = 2000
        }
      }
    }
  }

  assert {
    condition     = length(module.exascale_db_storage_vault.exascale_db_storage_vault_resources) == 1
    error_message = "A configured Dedicated Infrastructure vault must be created by the reusable vault child module."
  }

  assert {
    condition     = module.exascale_db_storage_vault.exascale_db_storage_vaults["dedicated"].exadata_infrastructure_id == "ocid1.cloudexadatainfrastructure.oc1..existing"
    error_message = "The vault must resolve an Exadata Infrastructure dependency key before calling OCI."
  }
}

run "plans_cloud_vm_cluster_with_external_storage_vault" {
  command = plan

  variables {
    exadata_database_dependency = {
      exascale_db_storage_vaults = {
        shared = {
          id             = "ocid1.exascaledbstoragevault.oc1..existing"
          compartment_id = "ocid1.compartment.oc1..database"
        }
      }
    }

    cloud_vm_clusters_configuration = {
      with_external_vault = {
        backup_subnet_id            = "ocid1.subnet.oc1..backup"
        compartment_id              = "ocid1.compartment.oc1..database"
        cpu_core_count              = 2
        display_name                = "dedicated-vm-cluster"
        exadata_infrastructure_id   = "ocid1.cloudexadatainfrastructure.oc1..existing"
        exascale_db_storage_vault_id = "shared"
        gi_version                  = "19.0.0.0"
        hostname                    = "dedicatedvm"
        ssh_public_keys             = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample"]
        subnet_id                   = "ocid1.subnet.oc1..primary"
      }
    }
  }

  assert {
    condition     = oci_database_cloud_vm_cluster.these["with_external_vault"].exascale_db_storage_vault_id == "ocid1.exascaledbstoragevault.oc1..existing"
    error_message = "A Cloud VM Cluster must resolve an external storage-vault dependency key before calling OCI."
  }
}

run "plans_cloud_vm_cluster_with_local_storage_vault" {
  command = plan

  variables {
    exascale_db_storage_vaults_configuration = {
      default_compartment_id = "ocid1.compartment.oc1..database"
      exascale_db_storage_vaults = {
        local = {
          availability_domain                = "test:AD-1"
          display_name                       = "dedicated-exascale-vault"
          exadata_infrastructure_id          = "ocid1.cloudexadatainfrastructure.oc1..existing"
          high_capacity_database_storage_gbs = 2000
        }
      }
    }

    cloud_vm_clusters_configuration = {
      with_local_vault = {
        backup_subnet_id            = "ocid1.subnet.oc1..backup"
        compartment_id              = "ocid1.compartment.oc1..database"
        cpu_core_count              = 2
        display_name                = "dedicated-vm-cluster"
        exadata_infrastructure_id   = "ocid1.cloudexadatainfrastructure.oc1..existing"
        exascale_db_storage_vault_id = "local"
        gi_version                  = "19.0.0.0"
        hostname                    = "dedicatedvm"
        ssh_public_keys             = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample"]
        subnet_id                   = "ocid1.subnet.oc1..primary"
      }
    }
  }

  assert {
    condition     = oci_database_cloud_vm_cluster.these["with_local_vault"].exascale_db_storage_vault_id == "ocid1.exascaledbstoragevault.oc1..local"
    error_message = "A Cloud VM Cluster must resolve a locally configured storage vault before calling OCI."
  }
}

run "plans_cloud_vm_cluster_without_storage_vault" {
  command = plan

  variables {
    cloud_vm_clusters_configuration = {
      without_vault = {
        backup_subnet_id         = "ocid1.subnet.oc1..backup"
        compartment_id            = "ocid1.compartment.oc1..database"
        cpu_core_count            = 2
        display_name              = "dedicated-vm-cluster"
        exadata_infrastructure_id = "ocid1.cloudexadatainfrastructure.oc1..existing"
        gi_version                = "19.0.0.0"
        hostname                  = "dedicatedvm"
        ssh_public_keys           = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample"]
        subnet_id                 = "ocid1.subnet.oc1..primary"
      }
    }
  }

  assert {
    condition     = length(oci_database_cloud_vm_cluster.these) == 1
    error_message = "A Cloud VM Cluster must remain valid without an Exascale DB Storage Vault."
  }
}

run "rejects_unknown_storage_vault_key" {
  command = plan

  variables {
    cloud_vm_clusters_configuration = {
      with_unknown_vault = {
        backup_subnet_id            = "ocid1.subnet.oc1..backup"
        compartment_id              = "ocid1.compartment.oc1..database"
        cpu_core_count              = 2
        display_name                = "dedicated-vm-cluster"
        exadata_infrastructure_id   = "ocid1.cloudexadatainfrastructure.oc1..existing"
        exascale_db_storage_vault_id = "not-configured"
        gi_version                  = "19.0.0.0"
        hostname                    = "dedicatedvm"
        ssh_public_keys             = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample"]
        subnet_id                   = "ocid1.subnet.oc1..primary"
      }
    }
  }

  expect_failures = [oci_database_cloud_vm_cluster.these["with_unknown_vault"]]
}
