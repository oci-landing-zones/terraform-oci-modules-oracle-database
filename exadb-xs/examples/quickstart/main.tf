module "exadb_xs" {
  source = "../.."

  module_name             = var.module_name
  compartments_dependency = var.compartments_dependency
  network_dependency      = var.network_dependency
  subscription_dependency = var.subscription_dependency
  exadb_xs_configuration  = var.exadb_xs_configuration
}
