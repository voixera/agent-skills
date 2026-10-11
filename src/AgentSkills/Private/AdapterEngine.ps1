# AdapterEngine.ps1
# Turns canonical SKILL.md content into the on-disk representation each agent
# expects. The transform is chosen by the agent's `format` field (see
# registry/agents.json), not by agent id, so new agents that share a format need
# no new code.
#
# Supported formats:
#   skill-md               -> <dir>/<skillId>/SKILL.md   (frontmatter preserved)
#   mdc-frontmatter        -> <dir>/<skillId>.mdc        (Cursor rule frontmatter)
#   instructions-md        -> <dir>/<skillId>.instructions.md (applyTo frontmatter)
#   markdown-rules         -> <dir>/<skillId>.md         (plain rule doc)
#   aggregated-instructions-> single file with a managed block (GEMINI.md / AGENTS.md)

Set-StrictMode -Version Latest

$script:AgentSkillsManagedBlockBegin = '<!-- agent-skills:begin -->'
$script:AgentSkillsManagedBlockEnd   = '<!-- agent-skills:end -->'

function Get-AgentSkillsManagedBlockMarkers {
    [CmdletBinding()]
    param()
    return [pscustomobject]@{
        Begin = $script:AgentSkillsManagedBlockBegin
        End   = $script:AgentSkillsManagedBlockEnd
    }
}

function Get-AgentSkillsAdapterById {
    <#
    .SYNOPSIS
        Returns the adapter descriptor for an agent (from the agents registry).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    return (Get-AgentDefinitionById -Id $Id -Registry $Registry)
}

function Get-AgentSkillsSupportedFormats {
    [CmdletBinding()]
    param()
    return @('skill-md', 'mdc-frontmatter', 'instructions-md', 'markdown-rules', 'aggregated-instructions')
}

function Test-AgentSkillsAgentSupportsSkill {
    <#
    .SYNOPSIS
        Returns $true when the skill lists the agent as supported.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $Skill,
        [Parameter(Mandatory)] [psobject] $Agent
    )
    return (@($Skill.agents) -contains $Agent.id)
}

function Get-AgentSkillsInstallPath {
    <#
    .SYNOPSIS
        Resolves the absolute destination path for a skill+agent+scope.

    .DESCRIPTION
        The registry path templates use `<skillId>` and `~`. `~` is expanded to
        the user's home directory only for the user scope. Project scope paths are
        resolved against the supplied project root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $Agent,
        [Parameter(Mandatory)] [string] $SkillId,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [Parameter(Mandatory)] [string] $ProjectRoot
    )

    $template = $null
    $props = @($Agent.paths.PSObject.Properties.Name)
    if ($props -contains $Scope) {
        $template = $Agent.paths.$Scope
    } else {
        throw "Agent '$($Agent.id)' does not support scope '$Scope'."
    }

    $expanded = $template -replace '<skillId>', $SkillId

    if ($Scope -eq 'user') {
        $homeDir = Get-AgentSkillsHomeDirectory
        $expanded = $expanded -replace '^~', $homeDir
        return (Join-Path $homeDir ($expanded -replace "^$([regex]::Escape($homeDir))[\\/]", ''))
    }

    # Project scope: strip a leading '~' defensively (should not occur) and join.
    $relative = $expanded -replace '^~[\\/]?', ''
    return (Join-Path $ProjectRoot $relative)
}

function Get-AgentSkillsHomeDirectory {
    <#
    .SYNOPSIS
        Returns the current user's home directory in a host-agnostic way.
    #>
    [CmdletBinding()]
    param()
    if ($env:USERPROFILE) { return $env:USERPROFILE }
    if ($env:HOME) { return $env:HOME }
    return (Resolve-Path -LiteralPath '~').ProviderPath
}

function ConvertTo-AgentSkillsMdcRule {
    <#
    .SYNOPSIS
        Produces a Cursor .mdc rule document from a skill.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $SkillContent
    )

    $desc = $SkillContent.Skill.description
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine("description: $($desc -replace '"', '\"')")
    [void]$sb.AppendLine('globs:')
    [void]$sb.AppendLine('alwaysApply: false')
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("# $($SkillContent.Skill.name)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($SkillContent.Body.TrimEnd())
    [void]$sb.AppendLine('')
    return $sb.ToString()
}

function ConvertTo-AgentSkillsInstructionsMd {
    <#
    .SYNOPSIS
        Produces a GitHub Copilot *.instructions.md document from a skill.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $SkillContent
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('applyTo: "**"')
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("# $($SkillContent.Skill.name)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($SkillContent.Body.TrimEnd())
    [void]$sb.AppendLine('')
    return $sb.ToString()
}

function ConvertTo-AgentSkillsMarkdownRule {
    <#
    .SYNOPSIS
        Produces a plain markdown rule document (Cline / Roo / Windsurf /
        Continue) from a skill. A short header records provenance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $SkillContent
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# $($SkillContent.Skill.name)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("> Generated from the Agent Skills skill ``$($SkillContent.Skill.id)`` (v$($SkillContent.Skill.version)).")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($SkillContent.Body.TrimEnd())
    [void]$sb.AppendLine('')
    return $sb.ToString()
}

function ConvertTo-AgentSkillsSkillMd {
    <#
    .SYNOPSIS
        Produces a native SKILL.md document (Codex / Claude Code). The canonical
        file is already in this shape, so the body is preserved verbatim and the
        frontmatter is normalised.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $SkillContent
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine("name: $($SkillContent.Skill.id)")
    [void]$sb.AppendLine("description: $($SkillContent.Skill.description)")
    [void]$sb.AppendLine('metadata:')
    [void]$sb.AppendLine("  category: $($SkillContent.Skill.category)")
    [void]$sb.AppendLine("  version: $($SkillContent.Skill.version)")
    [void]$sb.AppendLine('  agents: all')
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($SkillContent.Body.TrimStart())
    return $sb.ToString()
}

function ConvertTo-AgentSkillsRenderedContent {
    <#
    .SYNOPSIS
        Renders a skill into the content required by an agent's format.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [psobject] $SkillContent,
        [Parameter(Mandatory)] [psobject] $Agent
    )

    switch ($Agent.format) {
        'skill-md'                { return (ConvertTo-AgentSkillsSkillMd -SkillContent $SkillContent) }
        'mdc-frontmatter'         { return (ConvertTo-AgentSkillsMdcRule -SkillContent $SkillContent) }
        'instructions-md'         { return (ConvertTo-AgentSkillsInstructionsMd -SkillContent $SkillContent) }
        'markdown-rules'          { return (ConvertTo-AgentSkillsMarkdownRule -SkillContent $SkillContent) }
        'aggregated-instructions' { return (ConvertTo-AgentSkillsMarkdownRule -SkillContent $SkillContent) }
        default {
            throw "No renderer for format '$($Agent.format)' (agent '$($Agent.id)')."
        }
    }
}

function New-AgentSkillsManagedBlock {
    <#
    .SYNOPSIS
        Builds the managed block content for aggregated instruction files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [psobject[]] $SkillContents,
        [string] $ToolVersion = '1.0.0'
    )

    $markers = Get-AgentSkillsManagedBlockMarkers
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine($markers.Begin)
    [void]$sb.AppendLine("<!-- Managed by Agent Skills v$ToolVersion. Do not edit inside these markers; uninstall removes only this block. -->")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# Agent Skills')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('The following skills are installed. Read and follow them when relevant.')

    foreach ($sc in $SkillContents) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('---')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("## $($sc.Skill.name)")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine($sc.Body.TrimEnd())
    }

    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($markers.End)
    return $sb.ToString()
}

function Merge-AgentSkillsManagedBlock {
    <#
    .SYNOPSIS
        Inserts or replaces the managed block inside an existing aggregated file.

    .PARAMETER ExistingContent
        Current file content, or $null/empty when the file does not exist.

    .PARAMETER Block
        The managed block text (including markers).

    .OUTPUTS
        The new full file content.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()] [string] $ExistingContent,
        [Parameter(Mandatory)] [string] $Block
    )

    $markers = Get-AgentSkillsManagedBlockMarkers

    if ([string]::IsNullOrEmpty($ExistingContent)) {
        return ($Block.TrimEnd() + "`n")
    }

    $beginIdx = $ExistingContent.IndexOf($markers.Begin)
    $endIdx = $ExistingContent.IndexOf($markers.End)

    if ($beginIdx -ge 0 -and $endIdx -gt $beginIdx) {
        $before = $ExistingContent.Substring(0, $beginIdx)
        $afterStart = $endIdx + $markers.End.Length
        $after = if ($afterStart -lt $ExistingContent.Length) { $ExistingContent.Substring($afterStart) } else { '' }
        return ($before + $Block.TrimEnd() + $after)
    }

    # No existing block: append, keeping a separating blank line.
    $trimmed = $ExistingContent.TrimEnd()
    return ($trimmed + "`n`n" + $Block.TrimEnd() + "`n")
}

function Remove-AgentSkillsManagedBlock {
    <#
    .SYNOPSIS
        Removes the managed block, returning the remaining content and whether a
        block was found.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()] [string] $ExistingContent
    )

    $markers = Get-AgentSkillsManagedBlockMarkers
    if ([string]::IsNullOrEmpty($ExistingContent)) {
        return [pscustomobject]@{ Content = ''; Removed = $false }
    }

    $beginIdx = $ExistingContent.IndexOf($markers.Begin)
    $endIdx = $ExistingContent.IndexOf($markers.End)
    if ($beginIdx -lt 0 -or $endIdx -le $beginIdx) {
        return [pscustomobject]@{ Content = $ExistingContent; Removed = $false }
    }

    $before = $ExistingContent.Substring(0, $beginIdx)
    $afterStart = $endIdx + $markers.End.Length
    $after = if ($afterStart -lt $ExistingContent.Length) { $ExistingContent.Substring($afterStart) } else { '' }
    $remaining = ($before.TrimEnd() + $after.TrimStart())
    return [pscustomobject]@{ Content = $remaining; Removed = $true }
}
