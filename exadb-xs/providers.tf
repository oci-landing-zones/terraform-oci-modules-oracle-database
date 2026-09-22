# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

terraform {
  # Matches the autonomous-recovery-service module convention. The optional
  # object attributes used by this module require Terraform 1.3 or later; 1.5
  # is already the repository convention for newly introduced modules.
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 8.0.0"
    }
  }
}
