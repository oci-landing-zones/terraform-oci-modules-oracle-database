variable "module_name" {
  type    = string
  default = "exascale-db-storage-vault-quickstart"
}

variable "compartments_dependency" {
  type = any
}

variable "exascale_db_storage_vaults_configuration" {
  type = any
}
