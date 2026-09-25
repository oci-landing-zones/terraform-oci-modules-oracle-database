mock_provider "oci" {}

run "plans_xs_vault" {
  command = apply

  variables {
    compartments_dependency = {
      database = { id = "ocid1.compartment.oc1..test" }
    }
    exascale_db_storage_vaults_configuration = {
      default_compartment_id = "database"
      exascale_db_storage_vaults = {
        primary = {
          availability_domain                = "test:AD-1"
          display_name                       = "primary-vault"
          high_capacity_database_storage_gbs = 300
        }
      }
    }
  }

  assert {
    condition     = length(oci_database_exascale_db_storage_vault.these) == 1
    error_message = "The vault module must create one configured vault."
  }
}

run "plans_cloud_at_customer_vault" {
  command = apply

  variables {
    compartments_dependency = {
      database = { id = "ocid1.compartment.oc1..test" }
    }
    exadata_infrastructure_dependency = {
      c_at_c = {
        id             = "ocid1.exadatainfrastructure.oc1..test"
        compartment_id = "ocid1.compartment.oc1..test"
      }
    }
    exascale_db_storage_vaults_configuration = {
      default_compartment_id = "database"
      exascale_db_storage_vaults = {
        c_at_c = {
          availability_domain                = "test:AD-1"
          display_name                       = "c-at-c-vault"
          exadata_infrastructure_id          = "c_at_c"
          high_capacity_database_storage_gbs = 2000
        }
      }
    }
  }

  assert {
    condition     = oci_database_exascale_db_storage_vault.these["c_at_c"].exadata_infrastructure_id == "ocid1.exadatainfrastructure.oc1..test"
    error_message = "A Cloud@Customer Infrastructure dependency key must resolve before the vault is created."
  }
}

run "rejects_xs_capacity_below_minimum" {
  command = plan

  variables {
    exascale_db_storage_vaults_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          display_name                       = "invalid-vault"
          high_capacity_database_storage_gbs = 299
        }
      }
    }
  }

  expect_failures = [var.exascale_db_storage_vaults_configuration]
}

run "rejects_dedicated_capacity_below_minimum" {
  command = plan

  variables {
    exascale_db_storage_vaults_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          compartment_id                     = "ocid1.compartment.oc1..test"
          display_name                       = "invalid-dedicated-vault"
          exadata_infrastructure_id          = "ocid1.cloudexadatainfrastructure.oc1..test"
          high_capacity_database_storage_gbs = 1999
        }
      }
    }
  }

  expect_failures = [var.exascale_db_storage_vaults_configuration]
}

run "rejects_unresolved_dedicated_infrastructure" {
  command = plan

  variables {
    exascale_db_storage_vaults_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          compartment_id                     = "ocid1.compartment.oc1..test"
          display_name                       = "invalid-dedicated-vault"
          exadata_infrastructure_id          = "missing-infrastructure"
          high_capacity_database_storage_gbs = 2000
        }
      }
    }
  }

  expect_failures = [oci_database_exascale_db_storage_vault.these["invalid"]]
}
