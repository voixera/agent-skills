# Commands.ps1
# Public, user-facing functions that back the CLI verbs. Kept thin: they compose
# the private building blocks and return result records or plain objects.

Set-StrictMode -Version Latest

function Get-AgentSkillsList {
    <#
    .SYNOPSIS
        Lists installed skills known to the registry, optionally filtered.
    #>
    [CmdletBinding()]
    param(
        [string] $Category,
        [string] $Search,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }

    $skills = @($Registry.Skills.skills)
    if ($Category) { $skills = @($skills | Where-Object { $_.category -eq $Category }) }
    if ($Search) {
        $needle = $Search.ToLowerInvariant()
        $skills = @($skills | Where-Object {
            $_.id.ToLowerInvariant().Contains($needle) -or
            $_.name.ToLowerInvariant().Contains($needle) -or
            $_.description.ToLowerInvariant().Contains($needle)
        })
    }
    return $skills
}

function Get-AgentSkillsAgentList {
    [CmdletBinding()]
    param([psobject] $Registry)
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    return @($Registry.Agents.agents)
}

function Get-AgentSkillsPresetList {
    [CmdletBinding()]
    param([psobject] $Registry)
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    return @($Registry.Presets.presets)
}

function Get-AgentSkillsPresetSkills {
    <#
    .SYNOPSIS
        Expands a preset id into its skill ids, validating every reference.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $PresetId,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    $preset = Get-AgentSkillsPresetById -Id $PresetId -Registry $Registry

    foreach ($ref in @($preset.skills)) {
        [void](Get-AgentSkillsById -Id $ref -Registry $Registry)  # throws if unknown
    }
    return @($preset.skills)
}

function Test-AgentSkillsInstallation {
    <#
    .SYNOPSIS
        Verifies that files recorded in the manifest still exist and match their
        recorded hash. Reports drift as WARN, missing files as FAIL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [Parameter(Mandatory)] [string] $ProjectRoot
    )

    $manifest = Read-AgentSkillsManifest -ProjectRoot $ProjectRoot -Scope $Scope
    $results = New-Object System.Collections.Generic.List[object]

    if (@($manifest.files).Count -eq 0) {
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name "manifest ($Scope)" -Reason 'Nothing installed for this scope' -Category 'verify'))
        return $results.ToArray()
    }

    foreach ($e in @($manifest.files)) {
        if (-not (Test-Path -LiteralPath $e.path)) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name $e.relativePath -Message 'File recorded in manifest is missing' -Category 'verify'))
            continue
        }
        if ($e.hash) {
            $current = Get-AgentSkillsContentHashFromFile -Path $e.path
            if ($current -ne $e.hash) {
                $results.Add((New-AgentSkillsResult -Status 'WARN' -Name $e.relativePath -Message 'File has been modified since install' -Category 'verify'))
                continue
            }
        }
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $e.relativePath -Message 'present' -Category 'verify'))
    }

    return $results.ToArray()
}

function Get-AgentSkillsContentHashFromFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    # Normalise line endings so CRLF/LF differences do not read as tampering.
    $content = $content -replace "`r`n", "`n"
    return (Get-AgentSkillsStringHash -Text $content)
}

function Get-AgentSkillsDoctor {
    <#
    .SYNOPSIS
        Environment diagnostics: PowerShell version, registry validity, detected
        agent configuration directories, and installed manifests.
    #>
    [CmdletBinding()]
    param(
        [string] $ProjectRoot = (Get-Location).Path
    )

    $checks = New-Object System.Collections.Generic.List[object]

    # PowerShell version.
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $checks.Add((New-AgentSkillsResult -Status 'PASS' -Name 'PowerShell' -Message "v$($PSVersionTable.PSVersion)" -Category 'doctor'))
    } else {
        $checks.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'PowerShell' -Message "v$($PSVersionTable.PSVersion) is below the required 5.1" -Category 'doctor'))
    }

    # Registry validity.
    try {
        $reg = Get-AgentSkillsRegistry
        if ($reg.IsValid) {
            $checks.Add((New-AgentSkillsResult -Status 'PASS' -Name 'registry' -Message "$(@($reg.Skills.skills).Count) skills, $(@($reg.Agents.agents).Count) agents, $(@($reg.Presets.presets).Count) presets" -Category 'doctor'))
        } else {
            $checks.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'registry' -Message 'schema validation failed' -Category 'doctor'))
        }
    } catch {
        $checks.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'registry' -Message $_.Exception.Message -Category 'doctor'))
    }

    # Detected agents (project scope).
    try {
        $reg = Get-AgentSkillsRegistry
        foreach ($agent in @($reg.Agents.agents)) {
            $detected = $false
            foreach ($marker in @($agent.detect)) {
                if ($marker -like '~*') { continue }  # user markers reported separately
                $probe = Join-Path $ProjectRoot $marker
                if (Test-Path -LiteralPath $probe) { $detected = $true; break }
            }
            $status = if ($detected) { 'PASS' } else { 'SKIP' }
            $reason = if ($detected) { '' } else { 'No marker found in the current project' }
            $checks.Add((New-AgentSkillsResult -Status $status -Name "detect:$($agent.id)" -Message $(if ($detected) { 'found' } else { '' }) -Reason $reason -Category 'doctor'))
        }
    } catch {
        # already reported via registry check
    }

    # Installed manifests.
    foreach ($scope in @('project', 'user')) {
        try {
            $mp = Get-AgentSkillsManifestPath -ProjectRoot $ProjectRoot -Scope $scope
            if (Test-Path -LiteralPath $mp) {
                $m = Read-AgentSkillsManifest -ProjectRoot $ProjectRoot -Scope $scope
                $checks.Add((New-AgentSkillsResult -Status 'PASS' -Name "manifest:$scope" -Message "$(@($m.files).Count) file(s) tracked" -Category 'doctor'))
            } else {
                $checks.Add((New-AgentSkillsResult -Status 'SKIP' -Name "manifest:$scope" -Reason 'No installation recorded' -Category 'doctor'))
            }
        } catch {
            $checks.Add((New-AgentSkillsResult -Status 'FAIL' -Name "manifest:$scope" -Message $_.Exception.Message -Category 'doctor'))
        }
    }

    return $checks.ToArray()
}
