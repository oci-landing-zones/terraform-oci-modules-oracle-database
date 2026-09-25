mock_provider "oci" {}

run "plans_db_home_on_cloud_at_customer_vm_cluster" {
  command = apply

  variables {
    vm_cluster_dependency = {
      c_at_c = {
        id             = "ocid1.vmcluster.oc1..test"
        compartment_id = "ocid1.compartment.oc1..database"
      }
    }

    cloud_db_homes_configuration = {
      primary = {
        display_name  = "c-at-c-db-home"
        db_version    = "26.0.0.0"
        vm_cluster_id = "c_at_c"
      }
    }
  }

  assert {
    condition     = length(oci_database_db_home.these) == 1
    error_message = "A DB Home must accept an external Exadata Cloud@Customer VM Cluster dependency."
  }
}
