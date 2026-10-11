# Logging.ps1
# Central output helpers. Deliberately avoids relying on ANSI support: colour is
# opt-in and only applied when the host advertises capability. A machine-readable
# result record is used everywhere so the CLI, the validator, and the tests all
# speak the same vocabulary.

Set-StrictMode -Version Latest

# The canonical status vocabulary. Do not invent new statuses.
$script:AgentSkillsStatuses = @('PASS', 'FAIL', 'WARN', 'SKIP')

function Get-AgentSkillsStatusVocabulary {
    [CmdletBinding()]
    param()
    return $script:AgentSkillsStatuses
}

function Test-AgentSkillsStatus {
    <#
    .SYNOPSIS
        Returns $true when the supplied value is a known status token.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Status
    )
    return ($script:AgentSkillsStatuses -contains $Status)
}

function New-AgentSkillsResult {
    <#
    .SYNOPSIS
        Creates a normalised result record used by validation and installation.

    .DESCRIPTION
        Every check or install action returns one of these. A SKIP must always
        carry a Reason so that a skipped check is never silently treated as a
        pass.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-AgentSkillsStatus -Status $_ })]
        [string] $Status,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $Message = '',

        [string] $Reason = '',

        [string] $Category = 'general'
    )

    if ($Status -eq 'SKIP' -and [string]::IsNullOrWhiteSpace($Reason)) {
        # A skip without a reason is a logic error; make it explicit.
        throw "A SKIP result requires a non-empty Reason (check: '$Name')."
    }

    return [pscustomobject]@{
        Status   = $Status
        Name     = $Name
        Message  = $Message
        Reason   = $Reason
        Category = $Category
    }
}

function Test-AgentSkillsAnsiSupport {
    <#
    .SYNOPSIS
        Best-effort detection of ANSI colour support in the current host.
    #>
    [CmdletBinding()]
    param()

    # Honour an explicit opt-out used by the CLI (--no-color) and tests.
    if ($env:AGENT_SKILLS_NO_COLOR) { return $false }

    if ($env:NO_COLOR) { return $false }

    if ($env:AGENT_SKILLS_FORCE_COLOR) { return $true }

    try {
        if ($Host.UI -and $Host.UI.SupportsVirtualTerminal) { return $true }
    } catch {
        # Host does not expose the property.
    }

    # Fall back to a conservative default: colour off unless proven otherwise.
    return $false
}

function Write-AgentSkillsMessage {
    <#
    .SYNOPSIS
        Writes a human-readable line, optionally coloured.

    .PARAMETER Level
        One of: info, success, warning, error, muted, heading.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('info', 'success', 'warning', 'error', 'muted', 'heading')]
        [string] $Level,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Message,

        [switch] $NoNewline
    )

    $useColor = Test-AgentSkillsAnsiSupport

    $code = switch ($Level) {
        'success' { 'Green' }
        'warning' { 'Yellow' }
        'error'   { 'Red' }
        'muted'   { 'DarkGray' }
        'heading' { 'Cyan' }
        default   { $null }
    }

    $prefix = switch ($Level) {
        'success' { '[ok] ' }
        'warning' { '[warn] ' }
        'error'   { '[error] ' }
        default   { '' }
    }

    $text = "$prefix$Message"

    if ($useColor -and $code) {
        Write-Host $text -ForegroundColor $code -NoNewline:$NoNewline
    } else {
        Write-Host $text -NoNewline:$NoNewline
    }
}

function Format-AgentSkillsResultLine {
    <#
    .SYNOPSIS
        Renders a single result record as a fixed-width status line.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Result
    )

    $status = $Result.Status.PadRight(4)
    $line = "$status $($Result.Name)"
    if ($Result.Message) { $line += " - $($Result.Message)" }
    if ($Result.Status -eq 'SKIP' -and $Result.Reason) { $line += " (skipped: $($Result.Reason))" }
    return $line
}

function Write-AgentSkillsResults {
    <#
    .SYNOPSIS
        Prints a set of result records and a summary, then returns a summary object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [psobject[]] $Results
    )

    foreach ($r in $Results) {
        $level = switch ($r.Status) {
            'PASS' { 'success' }
            'FAIL' { 'error' }
            'WARN' { 'warning' }
            'SKIP' { 'muted' }
            default { 'info' }
        }
        Write-AgentSkillsMessage -Level $level -Message (Format-AgentSkillsResultLine -Result $r)
    }

    $summary = [pscustomobject]@{
        Pass = @($Results | Where-Object { $_.Status -eq 'PASS' }).Count
        Fail = @($Results | Where-Object { $_.Status -eq 'FAIL' }).Count
        Warn = @($Results | Where-Object { $_.Status -eq 'WARN' }).Count
        Skip = @($Results | Where-Object { $_.Status -eq 'SKIP' }).Count
        Total = @($Results).Count
    }

    Write-AgentSkillsMessage -Level 'heading' -Message ''
    Write-AgentSkillsMessage -Level 'heading' -Message (
        "Summary: {0} passed, {1} failed, {2} warnings, {3} skipped ({4} checks)." -f `
            $summary.Pass, $summary.Fail, $summary.Warn, $summary.Skip, $summary.Total)

    return $summary
}
