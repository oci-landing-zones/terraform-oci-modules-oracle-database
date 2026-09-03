# Preserve resource addresses when upgrading from the monolithic Exadata module.
moved {
  from = oci_database_db_home.these
  to   = module.common_database.oci_database_db_home.these
}

moved {
  from = oci_database_database.these
  to   = module.common_database.oci_database_database.these
}

moved {
  from = oci_database_pluggable_database.these
  to   = module.common_database.oci_database_pluggable_database.these
}
