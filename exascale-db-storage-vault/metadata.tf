# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  cislz_module_tag = {
    "ocilz-terraform-module" = fileexists("${path.module}/../release.txt") ? "${trimspace(var.module_name)}/${trimspace(file("${path.module}/../release.txt"))}" : trimspace(var.module_name)
  }
}
