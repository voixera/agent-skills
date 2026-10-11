# Test fixtures

Shared input files used by the test suite.

Fixtures here are intentionally small: tests that need a rich repository state
create it in an isolated temporary directory at run time (see
`Invoke-WithTempProject` in `tests/integration/Install.Tests.ps1`) rather than
committing large snapshots.

Add a fixture only when several tests would otherwise duplicate the same inline
data.
