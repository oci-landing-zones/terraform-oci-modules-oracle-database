mock_provider "oci" {}

run "plans_local_vault_and_cluster" {
  command = apply

  override_resource {
    target = oci_database_exadb_vm_cluster.these["primary"]
    values = {
      id = "ocid1.exadbvmcluster.oc1..primary"
    }
  }

  variables {
    compartments_dependency = {
      database = { id = "ocid1.compartment.oc1..test" }
    }
    network_dependency = {
      subnets = {
        client = { id = "ocid1.subnet.oc1..client" }
        backup = { id = "ocid1.subnet.oc1..backup" }
      }
      network_security_groups = {
        database = { id = "ocid1.networksecuritygroup.oc1..database" }
      }
    }
    exadb_xs_configuration = {
      default_compartment_id = "database"
      exascale_db_storage_vaults = {
        primary = {
          availability_domain                = "test:AD-1"
          additional_flash_cache_in_percent  = 0
          display_name                       = "primary-vault"
          high_capacity_database_storage_gbs = 1000
        }
      }
      exadb_vm_clusters = {
        primary = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "backup"
          display_name                 = "primary-cluster"
          exascale_db_storage_vault_id = "primary"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs01"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "client"
          node_names                   = ["node-1", "node-2"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
          nsg_ids = ["database"]
        }
      }
    }

    cloud_db_homes_configuration = {
      primary = {
        display_name  = "primary-db-home"
        db_version    = "26.0.0.0"
        vm_cluster_id = "primary"
      }
    }
  }

  assert {
    condition     = length(module.exascale_db_storage_vault.exascale_db_storage_vaults) == 1
    error_message = "The local storage-vault map must create one vault."
  }

  assert {
    condition     = length(oci_database_exadb_vm_cluster.these) == 1
    error_message = "The local VM-cluster map must create one ExaDB-XS VM cluster."
  }

  assert {
    condition     = oci_database_exadb_vm_cluster.these["primary"].exascale_db_storage_vault_id == module.exascale_db_storage_vault.exascale_db_storage_vaults["primary"].id
    error_message = "A local VM cluster must reference its locally created storage vault."
  }

  assert {
    condition     = length(module.common_database.database_resources.database_homes) == 1
    error_message = "A DB Home using a local ExaDB-XS VM Cluster key must be created through common-database."
  }
}

run "plans_cluster_with_external_vault" {
  command = apply

  variables {
    exadb_xs_dependency = {
      exascale_db_storage_vaults = {
        external = {
          id             = "ocid1.exascaledbstoragevault.oc1..external"
          compartment_id = "ocid1.compartment.oc1..test"
        }
      }
    }
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        external = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          compartment_id               = "ocid1.compartment.oc1..test"
          display_name                 = "external-vault-cluster"
          exascale_db_storage_vault_id = "external"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs-ext"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  assert {
    condition     = length(module.exascale_db_storage_vault.exascale_db_storage_vaults) == 0
    error_message = "An external vault dependency must not create a duplicate local vault."
  }

  assert {
    condition     = oci_database_exadb_vm_cluster.these["external"].exascale_db_storage_vault_id == "ocid1.exascaledbstoragevault.oc1..external"
    error_message = "The cluster must resolve the external vault logical key to its OCID."
  }
}

run "plans_db_home_on_external_exadb_xs_cluster" {
  command = apply

  variables {
    exadb_xs_dependency = {
      exadb_vm_clusters = {
        external = {
          id             = "ocid1.exadbvmcluster.oc1..external"
          compartment_id = "ocid1.compartment.oc1..database"
        }
      }
    }

    cloud_db_homes_configuration = {
      primary = {
        display_name  = "primary-db-home"
        db_version    = "26.0.0.0"
        vm_cluster_id = "external"
      }
    }
  }

  assert {
    condition     = length(module.common_database.database_resources.database_homes) == 1
    error_message = "An ExaDB-XS VM Cluster supplied through exadb_xs_dependency must support a DB Home."
  }
}

run "rejects_duplicate_node_names" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs02"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1", "node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_unresolved_subnet" {
  command = plan

  variables {
    compartments_dependency = {
      database = { id = "ocid1.compartment.oc1..test" }
    }
    exadb_xs_configuration = {
      default_compartment_id = "database"
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "missing-backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs03"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "missing-client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  expect_failures = [oci_database_exadb_vm_cluster.these["invalid"]]
}

run "rejects_xs_vault_capacity_below_console_minimum" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          display_name                       = "invalid-vault"
          high_capacity_database_storage_gbs = 299
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_invalid_flash_cache_percentage" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          additional_flash_cache_in_percent  = 33
          display_name                       = "invalid-vault"
          high_capacity_database_storage_gbs = 300
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_autoscale_limit_below_requested_capacity" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exascale_db_storage_vaults = {
        invalid = {
          availability_domain                = "test:AD-1"
          autoscale_limit_in_gbs             = 999
          display_name                       = "invalid-vault"
          high_capacity_database_storage_gbs = 1000
          is_autoscale_enabled               = true
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_vm_count_outside_console_range" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs04"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = [for index in range(11) : "node-${index}"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_ecpu_values_outside_console_rules" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs05"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 10
            total_ecpu_count_per_node                = 10
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_invalid_storage_mode" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs06"
          shape                        = "EXADB_XS"
          shape_attribute              = "UNSUPPORTED_STORAGE"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_invalid_hostname_license_port_and_zpr_count" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "1invalid-hostname"
          license_model                = "BYOL"
          scan_listener_port_tcp       = 1000
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
          security = {
            zpr_attributes = [
              { attr_name = "one", attr_value = "one" },
              { attr_name = "two", attr_value = "two" },
              { attr_name = "three", attr_value = "three" },
              { attr_name = "four", attr_value = "four" },
            ]
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "plans_zero_enabled_ecpus_for_existing_cluster_lifecycle" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        stopped = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          compartment_id               = "ocid1.compartment.oc1..test"
          display_name                 = "stopped-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs07"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 0
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 220
          }
        }
      }
    }
  }

  assert {
    condition     = length(oci_database_exadb_vm_cluster.these) == 1
    error_message = "A lifecycle configuration with zero enabled ECPUs must pass local validation."
  }
}

run "rejects_smart_file_system_below_console_minimum" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs08"
          shape                        = "EXADB_XS"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 219
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}

run "rejects_block_file_system_below_console_minimum" {
  command = plan

  variables {
    exadb_xs_configuration = {
      exadb_vm_clusters = {
        invalid = {
          availability_domain          = "test:AD-1"
          backup_subnet_id             = "ocid1.subnet.oc1..backup"
          display_name                 = "invalid-cluster"
          exascale_db_storage_vault_id = "ocid1.exascaledbstoragevault.oc1..vault"
          grid_image_id                = "ocid1.image.oc1..image"
          hostname                     = "exaxs09"
          shape                        = "EXADB_XS"
          shape_attribute              = "BLOCK_STORAGE"
          ssh_public_keys              = ["ssh-rsa test"]
          subnet_id                    = "ocid1.subnet.oc1..client"
          node_names                   = ["node-1"]
          node_config = {
            enabled_ecpu_count_per_node              = 8
            total_ecpu_count_per_node                = 8
            vm_file_system_storage_size_gbs_per_node = 259
          }
        }
      }
    }
  }

  expect_failures = [var.exadb_xs_configuration]
}
