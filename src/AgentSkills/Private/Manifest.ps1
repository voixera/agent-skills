# Manifest.ps1
# The installation manifest records every file the tool created or modified, plus
# the source skill/agent/scope. It is what makes uninstall safe: the tool only
# ever removes files it can prove it created.

Set-StrictMode -Version Latest

$script:AgentSkillsManifestFileName = '.agent-skills-manifest.json'

function Get-AgentSkillsManifestFileName {
    [CmdletBinding()]
    param()
    return $script:AgentSkillsManifestFileName
}

function Get-AgentSkillsManifestRoot {
    <#
    .SYNOPSIS
        Returns the directory that holds the manifest and backups for a scope.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope
    )

    if ($Scope -eq 'user') {
        return (Join-Path (Get-AgentSkillsHomeDirectory) '.agent-skills')
    }
    return (Join-Path $ProjectRoot '.agent-skills')
}

function Get-AgentSkillsManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope
    )
    return (Join-Path (Get-AgentSkillsManifestRoot -ProjectRoot $ProjectRoot -Scope $Scope) $script:AgentSkillsManifestFileName)
}

function Get-AgentSkillsBackupRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope
    )
    return (Join-Path (Get-AgentSkillsManifestRoot -ProjectRoot $ProjectRoot -Scope $Scope) 'backups')
}

function Read-AgentSkillsManifest {
    <#
    .SYNOPSIS
        Reads the manifest for a scope. Returns an empty manifest when none
        exists. A corrupt manifest is a hard error (never silently discarded).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope
    )

    $path = Get-AgentSkillsManifestPath -ProjectRoot $ProjectRoot -Scope $Scope
    if (-not (Test-Path -LiteralPath $path)) {
        return [pscustomobject]@{
            schemaVersion = 1
            toolVersion   = Get-AgentSkillsToolVersion
            scope         = $Scope
            updated       = Get-AgentSkillsTimestamp
            files         = @()
        }
    }

    $data = Read-AgentSkillsJson -Path $path
    if (-not ($data.PSObject.Properties.Name -contains 'files')) {
        throw "Manifest at '$path' is missing the 'files' property and cannot be trusted."
    }
    return $data
}

function Save-AgentSkillsManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope
    )

    $path = Get-AgentSkillsManifestPath -ProjectRoot $ProjectRoot -Scope $Scope
    $Manifest.updated = Get-AgentSkillsTimestamp
    $json = $Manifest | ConvertTo-Json -Depth 8
    Write-AgentSkillsFile -Path $path -Content ($json + "`n")
    return $path
}

function New-AgentSkillsManifestEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $RelativePath,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $SkillId,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $AgentId,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $SkillVersion,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [Parameter(Mandatory)] [ValidateSet('created', 'modified', 'managed-block')] [string] $Action,
        [string] $Backup = $null,
        [string] $Hash = $null,
        [AllowEmptyCollection()] [string[]] $SkillIds = @()
    )

    $entry = [pscustomobject]@{
        path         = $Path
        relativePath = $RelativePath
        skillId      = $SkillId
        agentId      = $AgentId
        skillVersion = $SkillVersion
        scope        = $Scope
        action       = $Action
        backup       = $Backup
        hash         = $Hash
        installedAt  = Get-AgentSkillsTimestamp
    }

    if ($SkillIds.Count -gt 0) {
        Add-Member -InputObject $entry -NotePropertyName 'skillIds' -NotePropertyValue $SkillIds -Force
    }

    return $entry
}

function New-AgentSkillsManifest {
    <#
    .SYNOPSIS
        Creates a fresh manifest object with the given file entries.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [AllowEmptyCollection()] [object[]] $Files = @()
    )
    return [pscustomobject]@{
        schemaVersion = 1
        toolVersion   = Get-AgentSkillsToolVersion
        scope         = $Scope
        updated       = Get-AgentSkillsTimestamp
        files         = @($Files)
    }
}

function Get-AgentSkillsManifestEntriesForSkill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Manifest,
        [string] $SkillId,
        [string] $AgentId
    )
    $entries = @($Manifest.files)
    if ($SkillId) { $entries = @($entries | Where-Object { $_.skillId -eq $SkillId }) }
    if ($AgentId) { $entries = @($entries | Where-Object { $_.agentId -eq $AgentId }) }
    return $entries
}
