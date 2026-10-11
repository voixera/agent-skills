# run-tests.ps1
# Runs the Agent Skills test suite. No Pester required.
#
# Usage:
#   .\tests\run-tests.ps1              # run all tests
#   .\tests\run-tests.ps1 -Suite unit  # run only unit tests
#   .\tests\run-tests.ps1 -Suite integration
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed
#   2  usage error

[CmdletBinding()]
param(
    [ValidateSet('all', 'unit', 'integration')]
    [string] $Suite = 'all'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$testsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $testsRoot

# Make the module loadable from a clean environment.
$modulePath = Join-Path $repoRoot 'src\AgentSkills\AgentSkills.psd1'
Import-Module -Name $modulePath -Force -ErrorAction Stop

. (Join-Path $testsRoot 'Harness.ps1')

# Never emit ANSI from tests.
$env:AGENT_SKILLS_NO_COLOR = '1'

$results = @()
switch ($Suite) {
    'unit'        { $results += Invoke-TestSuite -Name 'unit' -Path (Join-Path $testsRoot 'unit') }
    'integration' { $results += Invoke-TestSuite -Name 'integration' -Path (Join-Path $testsRoot 'integration') }
    'all' {
        $results += Invoke-TestSuite -Name 'unit' -Path (Join-Path $testsRoot 'unit')
        $results += Invoke-TestSuite -Name 'integration' -Path (Join-Path $testsRoot 'integration')
    }
}

# Keep only real result records (defensive against stray pipeline output).
$results = @($results | Where-Object { $_ -and ($_.PSObject.Properties.Name -contains 'Passed') })

$passed = @($results | Where-Object { $_.Passed }).Count
$failed = @($results | Where-Object { -not $_.Passed }).Count
$total = @($results).Count

Write-Host ""
Write-Host ('=' * 60)
Write-Host ("Tests: {0} total, {1} passed, {2} failed" -f $total, $passed, $failed) -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($r in @($results | Where-Object { -not $_.Passed })) {
        Write-Host ("  - {0} / {1}" -f $r.Group, $r.Name) -ForegroundColor Red
        Write-Host ("    {0}" -f $r.Error) -ForegroundColor DarkRed
    }
    exit 1
}

exit 0
