module "exascale_db_storage_vault" {
  source = "../.."

  module_name                              = var.module_name
  compartments_dependency                  = var.compartments_dependency
  exascale_db_storage_vaults_configuration = var.exascale_db_storage_vaults_configuration
}
