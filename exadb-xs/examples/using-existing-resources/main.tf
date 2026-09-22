module "exadb_xs" {
  source = "../.."

  compartments_dependency      = var.compartments_dependency
  exadb_xs_dependency          = var.exadb_xs_dependency
  cloud_db_homes_configuration = var.cloud_db_homes_configuration
}
