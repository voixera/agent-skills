# Harness.ps1
# Minimal, dependency-free test harness. It does not require Pester so the suite
# runs on a stock Windows PowerShell 5.1. It produces a non-zero exit code when
# any test fails, which is what CI needs.
#
# Usage:
#   . .\tests\Harness.ps1
#   Invoke-TestSuite -Name 'unit' -Path .\tests\unit
#
# Each *.Tests.ps1 file defines functions named like:
#   Test_<something>   (a test)
#   Assert-*           (helpers from this harness)

Set-StrictMode -Version Latest

$script:AgentSkillsTestResults = New-Object System.Collections.Generic.List[object]
$script:AgentSkillsCurrentGroup = '(root)'

function Describe {
    param([Parameter(Mandatory)] [string] $Name)
    $script:AgentSkillsCurrentGroup = $Name
    Write-Host ""
    Write-Host ("== {0} ==" -f $Name) -ForegroundColor Cyan
}
function It {
    <#
    .SYNOPSIS
        Runs a test block, catching failures.
    #>
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Body
    )
    $start = Get-Date
    try {
        # Discard any pipeline output from the test body; results are tracked
        # exclusively through the result record.
        $null = & $Body
        $script:AgentSkillsTestResults.Add([pscustomobject]@{
            Group = $script:AgentSkillsCurrentGroup; Name = $Name; Passed = $true; Error = ''; Ms = ((Get-Date) - $start).TotalMilliseconds
        })
        Write-Host ("  [PASS] {0}" -f $Name) -ForegroundColor Green
    } catch {
        $script:AgentSkillsTestResults.Add([pscustomobject]@{
            Group = $script:AgentSkillsCurrentGroup; Name = $Name; Passed = $false; Error = $_.Exception.Message; Ms = ((Get-Date) - $start).TotalMilliseconds
        })
        Write-Host ("  [FAIL] {0}" -f $Name) -ForegroundColor Red
        Write-Host ("         {0}" -f $_.Exception.Message) -ForegroundColor DarkRed
    }
}

function Assert-True {
    param([Parameter(Mandatory)] [bool] $Condition, [string] $Message = 'Expected $true.')
    if (-not $Condition) { throw $Message }
}

function Assert-False {
    param([Parameter(Mandatory)] [bool] $Condition, [string] $Message = 'Expected $false.')
    if ($Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string] $Message = '')
    if ($Expected -ne $Actual) {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Expected '{1}' but got '{2}'." -f $m, $Expected, $Actual)
    }
}

function Assert-NotEqual {
    param($NotExpected, $Actual, [string] $Message = '')
    if ($NotExpected -eq $Actual) {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Did not expect '{1}'." -f $m, $Actual)
    }
}

function Assert-Null {
    param($Value, [string] $Message = 'Expected $null.')
    if ($null -ne $Value) { throw $Message }
}

function Assert-NotNull {
    param($Value, [string] $Message = 'Expected a value.')
    if ($null -eq $Value) { throw $Message }
}

function Assert-Contains {
    param([Parameter(Mandatory)] $Collection, $Item, [string] $Message = '')
    if (@($Collection) -notcontains $Item) {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Collection does not contain '{1}'." -f $m, $Item)
    }
}

function Assert-Match {
    param([Parameter(Mandatory)] [string] $Text, [Parameter(Mandatory)] [string] $Pattern, [string] $Message = '')
    if ($Text -notmatch $Pattern) {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Text did not match '{1}'." -f $m, $Pattern)
    }
}

function Assert-NotMatch {
    param([Parameter(Mandatory)] [string] $Text, [Parameter(Mandatory)] [string] $Pattern, [string] $Message = '')
    if ($Text -match $Pattern) {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Text unexpectedly matched '{1}'." -f $m, $Pattern)
    }
}

function Assert-Throws {
    param([Parameter(Mandatory)] [scriptblock] $Body, [string] $MessagePattern = '')
    $threw = $false
    $msg = ''
    try { & $Body } catch { $threw = $true; $msg = $_.Exception.Message }
    if (-not $threw) { throw 'Expected the script block to throw, but it did not.' }
    if ($MessagePattern -and $msg -notmatch $MessagePattern) {
        throw ("Threw, but message '{0}' did not match '{1}'." -f $msg, $MessagePattern)
    }
}

function Assert-NoThrow {
    param([Parameter(Mandatory)] [scriptblock] $Body, [string] $Message = '')
    try { & $Body } catch {
        $m = if ($Message) { $Message + ' ' } else { '' }
        throw ("{0}Unexpectedly threw: {1}" -f $m, $_.Exception.Message)
    }
}

function New-TestTempDirectory {
    <#
    .SYNOPSIS
        Creates an isolated temp directory for a test. Callers are responsible
        for removing it; tests that fail mid-way are cleaned by the runner.
    #>
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("agentskills-test-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    return $path
}

function Invoke-TestSuite {
    <#
    .SYNOPSIS
        Loads and runs every *.Tests.ps1 file under the given directory.
    #>
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Path
    )

    Write-Host ""
    Write-Host ("### Test suite: {0} ###" -f $Name) -ForegroundColor Magenta

    $files = @(Get-ChildItem -LiteralPath $Path -Filter '*.Tests.ps1' -Recurse | Sort-Object FullName)
    foreach ($file in $files) {
        . $file.FullName
    }

    # Discover and run all functions named Test_* defined by the suites.
    $testFunctions = @(Get-ChildItem Function:\ | Where-Object { $_.Name -like 'Test_*' } | Sort-Object Name)
    foreach ($fn in $testFunctions) {
        $label = $fn.Name -replace '^Test_', '' -replace '_', ' '
        $scriptBlock = $fn.ScriptBlock
        It -Name $label -Body $scriptBlock
    }

    return $script:AgentSkillsTestResults.ToArray()
}

function Get-AgentSkillsTestResults {
    return $script:AgentSkillsTestResults.ToArray()
}

function Reset-AgentSkillsTestResults {
    $script:AgentSkillsTestResults.Clear()
}
