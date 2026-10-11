#Requires -Version 5.1
<#
.SYNOPSIS
    Agent Skills - Multi-Agent Skills Manager (CLI entry point).

.DESCRIPTION
    Installs modular skill packs into supported AI coding agents. Supports
    interactive and non-interactive use. Writes instruction/config files only;
    it never executes skill content.

.EXITCODES
    0  Success.
    1  Generic failure (validation error, refused operation).
    2  Invalid arguments / usage error.
    3  Conflict: an untracked file would be overwritten (rerun with -Force).
    4  Nothing to do / no matching selection.

.EXAMPLE
    .\install.ps1 list
    .\install.ps1 list -Category svg

.EXAMPLE
    .\install.ps1 install -Skills accessibility-a11y,responsive-design -Agents codex,claude-code -Scope project -Preview

.EXAMPLE
    .\install.ps1 install -Preset svg-specialist -Agents universal -Scope project -Yes
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Bootstrapping
# ---------------------------------------------------------------------------
$scriptPath = $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptPath
# install.ps1 lives in installer/ ; the module lives in ../src/
$moduleRoot = Join-Path (Split-Path -Parent $repoRoot) 'src\AgentSkills\AgentSkills.psd1'
if (-not (Test-Path -LiteralPath $moduleRoot)) {
    Write-Host "[error] Cannot find the Agent Skills module at $moduleRoot" -ForegroundColor Red
    exit 1
}
Import-Module -Name $moduleRoot -Force -ErrorAction Stop

$EXIT_SUCCESS  = 0
$EXIT_FAILURE  = 1
$EXIT_USAGE    = 2
$EXIT_CONFLICT = 3
$EXIT_NOTHING  = 4

# ---------------------------------------------------------------------------
# Simple argument parsing for the sub-commands.
# Kept minimal on purpose: a tiny table-driven parser is easier to audit than a
# framework, and works identically under PowerShell 5.1 and 7.
# ---------------------------------------------------------------------------
function ConvertFrom-CliArgs {
    param([string[]] $Tokens)

    $opts = @{
        Flags   = New-Object System.Collections.Generic.HashSet[string]
        Values  = @{}
    }

    $knownValueFlags = @('skills', 'agents', 'scope', 'preset', 'category', 'search', 'path', 'format')

    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        $t = $Tokens[$i]
        if ($t -match '^--?(.+)$') {
            $name = $Matches[1].ToLowerInvariant()
            $inline = $null
            if ($name -match '^([^=]+)=(.*)$') { $name = $Matches[1]; $inline = $Matches[2] }

            if ($knownValueFlags -contains $name -or $null -ne $inline) {
                $value = $null
                if ($null -ne $inline) {
                    $value = $inline
                } elseif ($i + 1 -lt $Tokens.Count -and $Tokens[$i + 1] -notmatch '^--?') {
                    $i++
                    $value = $Tokens[$i]
                } else {
                    $value = ''
                }
                $opts.Values[$name] = $value
            } else {
                [void]$opts.Flags.Add($name)
            }
        } else {
            # Positional token: treated as a search term for `search`, else ignored.
            if (-not $opts.Values.ContainsKey('search')) { $opts.Values['search'] = $t }
        }
    }

    return $opts
}

function ConvertTo-List {
    param([string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
    return @($Value -split '[,\s]+' | Where-Object { $_ -ne '' })
}

function Get-ProjectRoot {
    param($Opts)
    if ($Opts.Values.ContainsKey('path') -and $Opts.Values['path']) {
        $candidate = $Opts.Values['path']
        if (-not (Test-Path -LiteralPath $candidate)) {
            throw "Project path does not exist: $candidate"
        }
        return (Resolve-Path -LiteralPath $candidate).ProviderPath
    }
    return (Get-Location).Path
}

function Write-Banner {
    param([string] $Subtitle = 'Multi-Agent Skills Manager')
    $version = Get-AgentSkillsToolVersion
    $line = '-' * 54
    Write-Host ''
    Write-Host ('  ' + $line) -ForegroundColor DarkCyan
    Write-Host '   AGENT SKILLS' -ForegroundColor Cyan
    Write-Host ('   ' + $Subtitle + '  ' + ('v' + $version)) -ForegroundColor DarkGray
    Write-Host ('  ' + $line) -ForegroundColor DarkCyan
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

function Invoke-ListCommand {
    param($Opts)

    $category = if ($Opts.Values.ContainsKey('category')) { $Opts.Values['category'] } else { $null }
    $search = if ($Opts.Values.ContainsKey('search')) { $Opts.Values['search'] } else { $null }

    $skills = Get-AgentSkillsList -Category $category -Search $search
    if (@($skills).Count -eq 0) {
        Write-Host 'No skills matched.'
        return $EXIT_NOTHING
    }

    Write-Banner
    Write-Host ("{0,-32} {1,-12} {2}" -f 'ID', 'CATEGORY', 'NAME')
    Write-Host ("{0,-32} {1,-12} {2}" -f ('-' * 32), ('-' * 12), ('-' * 24))
    foreach ($s in $skills | Sort-Object category, id) {
        Write-Host ("{0,-32} {1,-12} {2}" -f $s.id, $s.category, $s.name)
    }
    Write-Host ''
    Write-Host ("{0} skill(s)." -f @($skills).Count)
    return $EXIT_SUCCESS
}

function Invoke-SearchCommand {
    param($Opts)

    if (-not $Opts.Values.ContainsKey('search') -or [string]::IsNullOrWhiteSpace($Opts.Values['search'])) {
        Write-Host '[error] search requires a term, e.g. `install.ps1 search svg`' -ForegroundColor Red
        return $EXIT_USAGE
    }
    $Opts.Values['category'] = $null
    return Invoke-ListCommand -Opts $Opts
}

function Invoke-AgentsCommand {
    param($Opts)
    Write-Banner
    Write-Host ("{0,-18} {1,-14} {2,-12} {3}" -f 'ID', 'SUPPORT', 'EVIDENCE', 'NAME')
    Write-Host ("{0,-18} {1,-14} {2,-12} {3}" -f ('-' * 18), ('-' * 14), ('-' * 12), ('-' * 24))
    foreach ($a in Get-AgentSkillsAgentList | Sort-Object id) {
        Write-Host ("{0,-18} {1,-14} {2,-12} {3}" -f $a.id, $a.supportLevel, $a.evidence, $a.name)
    }
    Write-Host ''
    Write-Host 'supportLevel: native = first-class skills; rules = rule documents; instructions = aggregated file.'
    return $EXIT_SUCCESS
}

function Invoke-PresetsCommand {
    param($Opts)
    Write-Banner
    foreach ($p in Get-AgentSkillsPresetList | Sort-Object id) {
        Write-Host ("{0,-24} {1}" -f $p.id, $p.name)
        Write-Host ("  {0}" -f $p.description)
        Write-Host ("  skills: {0}" -f (@($p.skills) -join ', '))
        Write-Host ''
    }
    return $EXIT_SUCCESS
}

function Invoke-ValidateCommand {
    param($Opts)

    $svgPath = if ($Opts.Values.ContainsKey('path')) { $Opts.Values['path'] } else { $null }
    if ($Opts.Flags.Contains('svg') -and $svgPath) {
        $results = Invoke-AgentSkillsSvgValidation -Path $svgPath
    } else {
        $results = Invoke-AgentSkillsValidation
    }

    Write-Banner
    $summary = Write-AgentSkillsResults -Results $results
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}

function Invoke-DoctorCommand {
    param($Opts)
    $projectRoot = Get-ProjectRoot -Opts $Opts
    Write-Banner
    $results = Get-AgentSkillsDoctor -ProjectRoot $projectRoot
    $summary = Write-AgentSkillsResults -Results $results
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}

function Invoke-VerifyCommand {
    param($Opts)
    $projectRoot = Get-ProjectRoot -Opts $Opts
    $scope = if ($Opts.Values.ContainsKey('scope') -and $Opts.Values['scope']) { $Opts.Values['scope'] } else { 'project' }

    Write-Banner
    $results = Test-AgentSkillsInstallation -Scope $scope -ProjectRoot $projectRoot
    $summary = Write-AgentSkillsResults -Results $results
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}

function Resolve-Selection {
    <#
    .SYNOPSIS
        Turns CLI options into a concrete list of skill ids (expanding a preset).
    #>
    param($Opts)

    $skillIds = @()
    if ($Opts.Values.ContainsKey('skills')) { $skillIds += ConvertTo-List -Value $Opts.Values['skills'] }
    if ($Opts.Values.ContainsKey('preset') -and $Opts.Values['preset']) {
        $presetSkills = Get-AgentSkillsPresetSkills -PresetId $Opts.Values['preset']
        $skillIds += $presetSkills
    }
    return @($skillIds | Select-Object -Unique)
}

function Get-AgentSelection {
    param($Opts, [switch] $Interactive)
    if ($Opts.Values.ContainsKey('agents') -and $Opts.Values['agents']) {
        return (ConvertTo-List -Value $Opts.Values['agents'])
    }
    return @()
}

function Show-Plan {
    param($Plan)

    $creates   = @($Plan.Actions | Where-Object { $_.Action -eq 'create' }).Count
    $overwrites = @($Plan.Actions | Where-Object { $_.Action -eq 'overwrite' }).Count
    $unchanged = @($Plan.Actions | Where-Object { $_.Action -eq 'unchanged' }).Count

    Write-Host ''
    Write-Host '  Summary' -ForegroundColor Cyan
    Write-Host ('    Scope   : {0}' -f $Plan.Scope)
    Write-Host ('    Root    : {0}' -f $Plan.ScopeRoot)
    Write-Host ('    Agents  : {0}' -f ($Plan.Agents -join ', '))
    Write-Host ('    Skills  : {0}' -f ($Plan.Resolved -join ', '))
    Write-Host ('    Changes : {0} new, {1} updated, {2} unchanged' -f $creates, $overwrites, $unchanged)
    if (@($Plan.AddedDependencies).Count -gt 0) {
        Write-Host ('    + deps  : {0}' -f ($Plan.AddedDependencies -join ', ')) -ForegroundColor Yellow
    }
    Write-Host ''

    if (@($Plan.Actions).Count -gt 0) {
        Write-Host '  Files' -ForegroundColor Cyan
        foreach ($a in $Plan.Actions) {
            $tag = switch ($a.Action) {
                'create'    { @{ Text = 'new    '; Color = 'Green' } }
                'overwrite' { @{ Text = 'update '; Color = 'Yellow' } }
                'unchanged' { @{ Text = 'same   '; Color = 'DarkGray' } }
                default     { @{ Text = $a.Action; Color = 'Gray' } }
            }
            Write-Host ('    ') -NoNewline
            Write-Host ('[{0}]' -f $tag.Text) -NoNewline -ForegroundColor $tag.Color
            Write-Host (' {0}' -f $a.RelativePath)
        }
    }

    if (@($Plan.Diagnostics).Count -gt 0) {
        Write-Host ''
        Write-Host '  Notes' -ForegroundColor Cyan
        foreach ($d in @($Plan.Diagnostics)) {
            $color = switch ($d.Status) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Gray' } }
            Write-Host ('    {0}' -f (Format-AgentSkillsResultLine -Result $d)) -ForegroundColor $color
        }
    }
    Write-Host ''
}


function Invoke-InstallCommand {
    param($Opts)

    $skillIds = Resolve-Selection -Opts $Opts
    $agentIds = Get-AgentSelection -Opts $Opts
    $scope = if ($Opts.Values.ContainsKey('scope') -and $Opts.Values['scope']) { $Opts.Values['scope'] } else { 'project' }
    $preview = $Opts.Flags.Contains('preview') -or $Opts.Flags.Contains('dry-run') -or $Opts.Flags.Contains('whatif')
    $assumeYes = $Opts.Flags.Contains('yes') -or $Opts.Flags.Contains('y')
    $force = $Opts.Flags.Contains('force')
    $noDeps = $Opts.Flags.Contains('no-dependencies')

    if (-not $skillIds -or -not $agentIds) {
        return Invoke-InteractiveInstall
    }

    $projectRoot = Get-ProjectRoot -Opts $Opts

    Write-Banner
    try {
        $plan = New-AgentSkillsInstallPlan -SkillIds $skillIds -AgentIds $agentIds -Scope $scope `
            -ProjectRoot $projectRoot -IncludeDependencies:(-not $noDeps)
    } catch {
        Write-Host ("[error] {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $EXIT_FAILURE
    }

    Show-Plan -Plan $plan

    if ($preview) {
        Write-Host 'Preview only. No files were written.'
        return $EXIT_SUCCESS
    }

    if (-not $assumeYes) {
        $answer = Read-Host 'Apply these changes? [y/N]'
        if ($answer -notmatch '^(y|yes)$') {
            Write-Host 'Aborted.'
            return $EXIT_SUCCESS
        }
    }

    $results = Invoke-AgentSkillsInstallPlan -Plan $plan -Force:$force
    Write-Host ''
    $summary = Write-AgentSkillsResults -Results $results

    if ($summary.Fail -gt 0) {
        # Distinguish a plain failure from a conflict for automation.
        $hasConflict = @($results | Where-Object { $_.Category -eq 'conflict' }).Count -gt 0
        if ($hasConflict) { return $EXIT_CONFLICT }
        return $EXIT_FAILURE
    }
    return $EXIT_SUCCESS
}

function Invoke-UninstallCommand {
    param($Opts)

    $scope = if ($Opts.Values.ContainsKey('scope') -and $Opts.Values['scope']) { $Opts.Values['scope'] } else { 'project' }
    $projectRoot = Get-ProjectRoot -Opts $Opts
    $all = $Opts.Flags.Contains('all')
    $whatIf = $Opts.Flags.Contains('preview') -or $Opts.Flags.Contains('dry-run')

    $skillIds = if ($Opts.Values.ContainsKey('skills')) { ConvertTo-List -Value $Opts.Values['skills'] } else { @() }
    $agentIds = if ($Opts.Values.ContainsKey('agents')) { ConvertTo-List -Value $Opts.Values['agents'] } else { @() }

    if (-not $all -and -not $skillIds -and -not $agentIds) {
        Write-Host '[error] uninstall requires -Skills, -Agents, or -All' -ForegroundColor Red
        return $EXIT_USAGE
    }

    Write-Banner
    try {
        $results = Invoke-AgentSkillsUninstall -Scope $scope -ProjectRoot $projectRoot `
            -SkillIds $skillIds -AgentIds $agentIds -All:$all -WhatIf:$whatIf
    } catch {
        Write-Host ("[error] {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $EXIT_FAILURE
    }

    $summary = Write-AgentSkillsResults -Results $results
    if ($whatIf) { Write-Host 'Preview only. No files were removed.' }
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}

function Invoke-UpdateCommand {
    param($Opts)

    # Update re-generates installed files from the current registry. It is a safe,
    # idempotent re-install of exactly what the manifest says is installed.
    $scope = if ($Opts.Values.ContainsKey('scope') -and $Opts.Values['scope']) { $Opts.Values['scope'] } else { 'project' }
    $projectRoot = Get-ProjectRoot -Opts $Opts

    Write-Banner
    $manifest = Read-AgentSkillsManifest -ProjectRoot $projectRoot -Scope $scope
    if (@($manifest.files).Count -eq 0) {
        Write-Host 'Nothing installed for this scope.'
        return $EXIT_NOTHING
    }

    # Group installed entries by agent, then reinstall their skills.
    $agentIds = @($manifest.files | ForEach-Object { $_.agentId } | Where-Object { $_ } | Select-Object -Unique)
    $skillIds = @()
    foreach ($f in @($manifest.files)) {
        if ($f.PSObject.Properties.Name -contains 'skillIds' -and $f.skillIds) { $skillIds += @($f.skillIds) }
        elseif ($f.skillId) { $skillIds += @($f.skillId -split ',\s*') }
    }
    $skillIds = @($skillIds | Where-Object { $_ } | Select-Object -Unique)

    if (-not $skillIds -or -not $agentIds) {
        Write-Host 'Manifest contains no restorable skills.'
        return $EXIT_NOTHING
    }

    try {
        $plan = New-AgentSkillsInstallPlan -SkillIds $skillIds -AgentIds $agentIds -Scope $scope -ProjectRoot $projectRoot
    } catch {
        Write-Host ("[error] {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $EXIT_FAILURE
    }

    Show-Plan -Plan $plan
    $results = Invoke-AgentSkillsInstallPlan -Plan $plan -Force
    $summary = Write-AgentSkillsResults -Results $results
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}

# ---------------------------------------------------------------------------
# Interactive installer
# ---------------------------------------------------------------------------
function Test-InteractiveConsole {
    <#
    .SYNOPSIS
        True when we can read individual keys (arrow-key navigation available).
        False in redirected/piped hosts, where we fall back to numbered input.
    #>
    try {
        if ([Console]::IsInputRedirected) { return $false }
    } catch { return $false }
    try { return -not $Host.UI.RawUI.KeyAvailable -or $true } catch { return $false }
}

function Read-Key {
    <#
    .SYNOPSIS
        Reads a single key without echoing it. Returns an object with Key and
        Char. Only called when Test-InteractiveConsole is true.
    #>
    $k = [Console]::ReadKey($true)
    return [pscustomobject]@{ Key = $k.Key; Char = $k.KeyChar }
}

function Write-Checkbox {
    param([bool] $Checked, [string] $Text, [bool] $Active)
    $box = if ($Checked) { '[x]' } else { '[ ]' }
    $pointer = if ($Active) { '>' } else { ' ' }
    if ($Active) {
        Write-Host "   $pointer $box $Text" -ForegroundColor White
    } else {
        Write-Host "     $box $Text"
    }
}

function Read-InteractiveMultiSelect {
    <#
    .SYNOPSIS
        Checkbox multi-select with arrow keys + space to toggle, Enter to confirm.
        Falls back to a numbered prompt when the console cannot read keys.

    .OUTPUTS
        Array of selected items. Never called with an empty result unless the
        caller allows it.
    #>
    param(
        [Parameter(Mandatory)] [string] $Prompt,
        [Parameter(Mandatory)] [object[]] $Items,
        [Parameter(Mandatory)] [scriptblock] $Display,
        [scriptblock] $Detail,
        [switch] $AllowEmpty,
        [switch] $AllowBack
    )

    $count = $Items.Count
    if ($count -eq 0) { return @() }

    if (-not (Test-InteractiveConsole)) {
        return Read-NumberedMultiSelect -Prompt $Prompt -Items $Items -Display $Display -Detail $Detail -AllowEmpty:$AllowEmpty
    }

    $checked = New-Object bool[] $count
    $cursor = 0

    $render = {
        for ($i = 0; $i -lt $count; $i++) {
            $active = ($i -eq $cursor)
            $label = (& $Display $Items[$i])
            if ($Detail) {
                $d = (& $Detail $Items[$i])
                if ($d) { $label = "$label  " + $d }
            }
            Write-Checkbox -Checked $checked[$i] -Text $label -Active $active
        }
    }

    Write-Host ''
    Write-Host "   $Prompt" -ForegroundColor Cyan
    Write-Host '   (up/down move, space toggles, "a" all, enter confirms)' -ForegroundColor DarkGray

    $render.Invoke()
    while ($true) {
        $key = Read-Key
        switch ($key.Key) {
            'UpArrow'   { $cursor = ($cursor - 1 + $count) % $count; Clear-Lines $count; $render.Invoke() }
            'DownArrow' { $cursor = ($cursor + 1) % $count; Clear-Lines $count; $render.Invoke() }
            'Spacebar'  {
                if (-not $AllowEmpty -and @($checked | Where-Object { $_ }).Count -eq 1 -and $checked[$cursor]) {
                    # Prevent deselecting the last item when empty is not allowed.
                } else {
                    $checked[$cursor] = -not $checked[$cursor]
                }
                Clear-Lines $count; $render.Invoke()
            }
            'Enter' {
                $picked = @()
                for ($i = 0; $i -lt $count; $i++) { if ($checked[$i]) { $picked += $Items[$i] } }
                if ($picked.Count -eq 0 -and -not $AllowEmpty) {
                    Write-Host '   Select at least one. ' -ForegroundColor Yellow
                    continue
                }
                return $picked
            }
            default {
                if ($key.Char -eq 'a' -or $key.Char -eq 'A') {
                    $all = @($checked | Where-Object { $_ }).Count -ne $count
                    for ($i = 0; $i -lt $count; $i++) { $checked[$i] = $all }
                    Clear-Lines $count; $render.Invoke()
                }
            }
        }
    }
}

function Read-InteractiveSingleSelect {
    param(
        [Parameter(Mandatory)] [string] $Prompt,
        [Parameter(Mandatory)] [object[]] $Items,
        [Parameter(Mandatory)] [scriptblock] $Display,
        [switch] $AllowBack
    )

    $count = $Items.Count
    if ($count -eq 0) { return $null }

    if (-not (Test-InteractiveConsole)) {
        return Read-NumberedSingleSelect -Prompt $Prompt -Items $Items -Display $Display -AllowBack:$AllowBack
    }

    $cursor = 0
    $render = {
        for ($i = 0; $i -lt $count; $i++) {
            $active = ($i -eq $cursor)
            $label = (& $Display $Items[$i])
            if ($active) { Write-Host "   > $label" -ForegroundColor White }
            else { Write-Host "     $label" }
        }
        if ($AllowBack) { Write-Host '     (Esc to go back)' -ForegroundColor DarkGray }
    }

    Write-Host ''
    Write-Host "   $Prompt" -ForegroundColor Cyan
    Write-Host '   (up/down move, enter selects)' -ForegroundColor DarkGray
    $render.Invoke()
    while ($true) {
        $key = Read-Key
        switch ($key.Key) {
            'UpArrow'   { $cursor = ($cursor - 1 + $count) % $count; Clear-Lines ($count + $(if ($AllowBack) { 1 } else { 0 })); $render.Invoke() }
            'DownArrow' { $cursor = ($cursor + 1) % $count; Clear-Lines ($count + $(if ($AllowBack) { 1 } else { 0 })); $render.Invoke() }
            'Enter'     { return $Items[$cursor] }
            'Escape'    { if ($AllowBack) { return $null } }
        }
    }
}

function Clear-Lines {
    param([int] $Count)
    for ($i = 0; $i -lt $Count; $i++) {
        $pos = [Console]::CursorLeft
        [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
        Write-Host (' ' * [Math]::Max(1, [Console]::BufferWidth - 1))
        [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
    }
}

# ---------- numbered fallbacks (redirected hosts) ----------

function Read-NumberedMultiSelect {
    param(
        [string] $Prompt,
        [object[]] $Items,
        [scriptblock] $Display,
        [scriptblock] $Detail,
        [switch] $AllowEmpty
    )
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $label = (& $Display $Items[$i])
        if ($Detail) { $d = (& $Detail $Items[$i]); if ($d) { $label = "$label  $d" } }
        Write-Host ("  [{0,2}] {1}" -f ($i + 1), $label)
    }
    Write-Host '  (enter numbers separated by commas, or "all")'
    while ($true) {
        $raw = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($raw)) {
            if ($AllowEmpty) { return @() }
            Write-Host '  Please choose at least one.'; continue
        }
        if ($raw.Trim().ToLowerInvariant() -eq 'all') { return @($Items) }
        $chosen = @(); $valid = $true
        foreach ($part in ($raw -split ',')) {
            $p = $part.Trim()
            if ($p -eq '') { continue }
            if ($p -notmatch '^\d+$' -or [int]$p -lt 1 -or [int]$p -gt $Items.Count) {
                Write-Host ("  '{0}' is not a valid choice." -f $p); $valid = $false; break
            }
            $chosen += $Items[[int]$p - 1]
        }
        if ($valid -and $chosen.Count -gt 0) { return @($chosen) }
    }
}

function Read-NumberedSingleSelect {
    param(
        [string] $Prompt,
        [object[]] $Items,
        [scriptblock] $Display,
        [switch] $AllowBack
    )
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host ("  [{0,2}] {1}" -f ($i + 1), (& $Display $Items[$i]))
    }
    if ($AllowBack) { Write-Host ("  [{0,2}] Back" -f ($Items.Count + 1)) }
    while ($true) {
        $raw = Read-Host $Prompt
        if ($raw -match '^\d+$') {
            $n = [int]$raw
            if ($n -ge 1 -and $n -le $Items.Count) { return $Items[$n - 1] }
            if ($AllowBack -and $n -eq $Items.Count + 1) { return $null }
        }
        Write-Host '  Invalid choice.'
    }
}


function Write-Section {
    param([string] $Step, [string] $Title)
    Write-Host ''
    Write-Host ("  {0}  {1}" -f $Step, $Title) -ForegroundColor Cyan
}

function Invoke-InteractiveInstall {
    Write-Banner
    Write-Host '  Welcome. A few choices and we will install your skills.' -ForegroundColor Gray

    $projectRoot = (Get-Location).Path

    # Step 1 - scope.
    Write-Section -Step '1/4' -Title 'Where should skills be installed?'
    $scopeItems = @(
        [pscustomobject]@{ id = 'project'; name = 'This project'; hint = "($projectRoot)" },
        [pscustomobject]@{ id = 'user';    name = 'My user profile'; hint = '(applies everywhere)' }
    )
    $scopeItem = Read-InteractiveSingleSelect -Prompt 'Installation scope' -Items $scopeItems `
        -Display { param($s) "$($s.name)  $($s.hint)" } -AllowBack
    if ($null -eq $scopeItem) { Write-Host '  Cancelled.'; return $EXIT_SUCCESS }
    $scope = $scopeItem.id

    # Step 2 - agents.
    Write-Section -Step '2/4' -Title 'Which AI agents do you use?'
    $agents = @(Get-AgentSkillsAgentList | Where-Object { @($_.scopes) -contains $scope } | Sort-Object id)
    $selectedAgents = Read-InteractiveMultiSelect -Prompt 'Agents (space to toggle, enter to confirm)' `
        -Items $agents `
        -Display { param($a) $a.name } `
        -Detail { param($a) "[$($a.supportLevel)]" }
    $agentIds = @($selectedAgents | ForEach-Object { $_.id })
    Write-Host ("  Selected: {0}" -f ($selectedAgents.name -join ', ')) -ForegroundColor Green

    # Step 3 - preset or custom.
    Write-Section -Step '3/4' -Title 'Start from a preset, or pick skills yourself?'
    $presets = @(Get-AgentSkillsPresetList | Sort-Object id)
    $presetItems = @($presets) + @([pscustomobject]@{ id = '__custom__'; name = 'Custom'; description = 'Choose individual skills' })
    $preset = Read-InteractiveSingleSelect -Prompt 'Preset' -Items $presetItems `
        -Display { param($p) $p.name } -AllowBack
    if ($null -eq $preset) { Write-Host '  Cancelled.'; return $EXIT_SUCCESS }

    if ($preset.id -eq '__custom__') {
        $allSkills = @(Get-AgentSkillsList | Sort-Object category, id)
        $chosen = Read-InteractiveMultiSelect -Prompt 'Skills (space to toggle, "a" selects all)' `
            -Items $allSkills `
            -Display { param($s) $s.name } `
            -Detail { param($s) "($($s.category))" }
        $skillIds = @($chosen | ForEach-Object { $_.id })
    } else {
        $skillIds = @(Get-AgentSkillsPresetSkills -PresetId $preset.id)
        Write-Host ("  Preset '{0}' includes {1} skill(s)." -f $preset.name, $skillIds.Count) -ForegroundColor Green
    }

    # Step 4 - preview and confirm.
    Write-Section -Step '4/4' -Title 'Review'
    try {
        $plan = New-AgentSkillsInstallPlan -SkillIds $skillIds -AgentIds $agentIds -Scope $scope -ProjectRoot $projectRoot
    } catch {
        Write-Host ("  [error] {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $EXIT_FAILURE
    }

    Show-Plan -Plan $plan

    $answer = Read-Host '  Apply these changes? [y/N]'
    if ($answer -notmatch '^(y|yes)$') { Write-Host '  Aborted.'; return $EXIT_SUCCESS }

    $results = Invoke-AgentSkillsInstallPlan -Plan $plan
    Write-Host ''
    $summary = Write-AgentSkillsResults -Results $results

    if ($summary.Fail -eq 0) {
        Write-Host ''
        Write-Host '  Done. Your agents will pick up the skills in a new session.' -ForegroundColor Green
    }
    if ($summary.Fail -gt 0) { return $EXIT_FAILURE }
    return $EXIT_SUCCESS
}


function Show-Help {
    Write-Banner
    @'
Usage: install.ps1 <command> [options]

Commands:
  (no command)            Run the interactive installer.
  list                    List available skills.
  search <term>           Search skills by id, name, or description.
  agents                  List supported AI agents.
  presets                 List skill presets.
  install                 Install skills (interactive if -Skills/-Agents omitted).
  uninstall               Remove installed skills.
  update                  Re-apply installed skills from the registry.
  verify                  Verify installed files against the manifest.
  validate                Validate the registry and all skills.
  doctor                  Diagnose the environment and detected agents.
  help                    Show this help.

Common options:
  -Skills <a,b>           Comma-separated skill ids.
  -Agents <a,b>           Comma-separated agent ids.
  -Preset <id>            Use a preset's skill set.
  -Scope project|user     Installation scope (default: project).
  -Path <dir>             Project directory (default: current directory).
  -Category <name>        Filter by category (list only).
  -Preview                Show the plan without changing files.
  -Force                  Overwrite untracked files (a backup is taken).
  -Yes                    Do not prompt for confirmation.
  -No-Dependencies        Do not pull in skill dependencies.

Examples:
  .\install.ps1 list -Category svg
  .\install.ps1 install -Preset svg-specialist -Agents codex,claude-code -Scope project -Preview
  .\install.ps1 install -Skills accessibility-a11y -Agents universal -Yes
  .\install.ps1 verify -Scope project
  .\install.ps1 uninstall -Skills accessibility-a11y -Scope project
'@ | Write-Host
    return $EXIT_SUCCESS
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
$commandName = if ($Command) { $Command.ToLowerInvariant() } else { '' }
if ($Rest) {
    # Allow `install.ps1 install -Skills ...` (options after the command).
    $opts = ConvertFrom-CliArgs -Tokens $Rest
} else {
    $opts = ConvertFrom-CliArgs -Tokens @()
}

# Support `-Help` / `--help` as the first token.
if ($Command -match '^-' ) {
    $opts = ConvertFrom-CliArgs -Tokens (@($Command) + @($Rest))
    $commandName = 'help'
}

try {
    switch ($commandName) {
        ''            { exit (Invoke-InteractiveInstall) }
        'help'        { exit (Show-Help) }
        '--help'      { exit (Show-Help) }
        '-h'          { exit (Show-Help) }
        'list'        { exit (Invoke-ListCommand -Opts $opts) }
        'search'      { exit (Invoke-SearchCommand -Opts $opts) }
        'agents'      { exit (Invoke-AgentsCommand -Opts $opts) }
        'presets'     { exit (Invoke-PresetsCommand -Opts $opts) }
        'install'     { exit (Invoke-InstallCommand -Opts $opts) }
        'uninstall'   { exit (Invoke-UninstallCommand -Opts $opts) }
        'update'      { exit (Invoke-UpdateCommand -Opts $opts) }
        'verify'      { exit (Invoke-VerifyCommand -Opts $opts) }
        'validate'    { exit (Invoke-ValidateCommand -Opts $opts) }
        'doctor'      { exit (Invoke-DoctorCommand -Opts $opts) }
        default {
            Write-Host ("[error] Unknown command: '{0}'. Run `install.ps1 help`." -f $Command) -ForegroundColor Red
            exit $EXIT_USAGE
        }
    }
} catch {
    Write-Host ("[error] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit $EXIT_FAILURE
}
