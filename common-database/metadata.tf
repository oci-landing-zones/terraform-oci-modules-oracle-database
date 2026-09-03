# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  cislz_module_tag = {
    "ocilz-terraform-module" = fileexists("${path.module}/../release.txt") ? "${var.module_name}/${file("${path.module}/../release.txt")}" : var.module_name
  }
}
