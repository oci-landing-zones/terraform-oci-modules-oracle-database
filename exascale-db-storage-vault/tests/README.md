# Module tests

`storage_vault.tftest.hcl` is a mocked Terraform suite. It proves local vault
creation and fail-fast capacity/dependency rules without OCI credentials or an
OCI apply. The suite needs Terraform 1.7 or later to support `mock_provider`.

Authenticated OCI tests remain necessary for Dedicated Infrastructure maximum
capacity, service quotas, policy permissions, vault lifecycle operations, and
consumer VM Cluster compatibility.
