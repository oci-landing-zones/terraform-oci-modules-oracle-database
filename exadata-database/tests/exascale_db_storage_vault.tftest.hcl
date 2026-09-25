mock_provider "oci" {}

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
