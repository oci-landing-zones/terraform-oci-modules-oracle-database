variable "module_name" {
  type    = string
  default = "exadb-xs-quickstart"
}

variable "compartments_dependency" {
  type = any
}

variable "network_dependency" {
  type = any
}

variable "subscription_dependency" {
  type    = any
  default = null
}

variable "exadb_xs_configuration" {
  type = any
}
