# Module tests

`exadb_xs.tftest.hcl` is a Terraform-native, mocked-provider test suite. It
requires a Terraform test runner that supports `mock_provider` (Terraform 1.7 or
later) and access to download the OCI provider constrained by this module. It
does not require OCI credentials and does not contact or apply infrastructure.

The module's public Terraform requirement remains `>= 1.5.0`; the newer version
is required only by the local test runner, not by module consumers.

The suite includes a positive local vault/VM Cluster wiring test and negative
tests for console-derived static rules: XS vault capacity, Flash Cache
percentage, node count, ECPU ranges/multiples including the zero-enabled
lifecycle value, Smart/Block filesystem minimums, storage mode, hostname,
license constant, SCAN port, and the ZPR attribute limit.

The suite also records one database/storage guardrail that can currently be
evaluated locally:

- A VM Cluster accepts exactly one `exascale_db_storage_vault_id` **string**;
  the typed variable contract rejects a list of two vault OCIDs before any
  provider operation. Terraform's native test runner rejects malformed test
  input before it can evaluate `expect_failures`, so this particular type-boundary
  failure cannot be represented as a passing `*.tftest.hcl` negative run. Keep
  it as a CI contract check: run `terraform plan` with a deliberately invalid
  `.tfvars` value containing a list, and assert that it exits non-zero with
  `attribute \"exascale_db_storage_vault_id\": string required`.

The following test is deliberately deferred, rather than represented by a
misleading mock: `rejects_existing_vault_with_incompatible_storage_type`. The
current external-vault dependency contract exposes only an ID; it does not
include OCI's storage type. Implement the test when the coordinated
`cluster_type`/`storage_type` dependency fields and their precondition are
available. It must reject a Smart cluster paired with an existing Block vault,
and the reverse combination, while accepting matching combinations. A real OCI
test tenancy is still required because the compatibility is ultimately enforced
by OCI resource state.

OCI-backed constraints such as existing-vault compatibility and database
version compatibility with storage mode and Grid Image are intentionally not
mocked and must be verified in a suitable test tenancy.
