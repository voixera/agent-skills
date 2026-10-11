# SkillContent.ps1
# Reads and normalises a canonical SKILL.md file: YAML-ish frontmatter plus the
# Markdown body. A full YAML parser is not assumed to be present, so the
# frontmatter reader supports the subset the repository actually uses
# (scalar strings, and one level of nested maps such as `metadata:`).

Set-StrictMode -Version Latest

function Read-AgentSkillsFrontmatter {
    <#
    .SYNOPSIS
        Splits a SKILL.md file into frontmatter (as an ordered hashtable) and body.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Content
    )

    $result = [ordered]@{}
    $body = $Content

    $normalised = $Content -replace "`r`n", "`n"
    if ($normalised -notmatch '^\s*---\s*\n') {
        return [pscustomobject]@{ Frontmatter = $result; Body = $body; HasFrontmatter = $false }
    }

    $lines = $normalised -split "`n"
    # Find the closing delimiter (the next line that is exactly '---').
    $endIndex = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*---\s*$') { $endIndex = $i; break }
    }

    if ($endIndex -lt 0) {
        return [pscustomobject]@{ Frontmatter = $result; Body = $body; HasFrontmatter = $false }
    }

    $fmLines = $lines[1..($endIndex - 1)]
    $bodyLines = if ($endIndex + 1 -le $lines.Count - 1) { $lines[($endIndex + 1)..($lines.Count - 1)] } else { @() }
    $body = ($bodyLines -join "`n").TrimStart("`n")

    $currentMap = $null
    foreach ($raw in $fmLines) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        if ($raw -match '^\s*#') { continue }

        # Nested key (indented) belonging to the current map.
        if ($raw -match '^\s+([A-Za-z0-9_\-]+)\s*:\s*(.*)$') {
            if ($null -eq $currentMap) { continue }
            $key = $Matches[1]
            $val = ConvertTo-AgentSkillsScalar -Value $Matches[2]
            $result[$currentMap][$key] = $val
            continue
        }

        # Top-level key.
        if ($raw -match '^([A-Za-z0-9_\-]+)\s*:\s*(.*)$') {
            $key = $Matches[1]
            $val = $Matches[2]
            if ([string]::IsNullOrWhiteSpace($val)) {
                # Start of a nested map.
                $currentMap = $key
                $result[$key] = [ordered]@{}
            } else {
                $currentMap = $null
                $result[$key] = ConvertTo-AgentSkillsScalar -Value $val
            }
        }
    }

    return [pscustomobject]@{
        Frontmatter    = $result
        Body           = $body
        HasFrontmatter = $true
    }
}

function ConvertTo-AgentSkillsScalar {
    <#
    .SYNOPSIS
        Converts a raw frontmatter value into a PowerShell scalar.
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string] $Value
    )

    if ($null -eq $Value) { return '' }
    $v = $Value.Trim()

    # Strip matching surrounding quotes.
    if ($v.Length -ge 2 -and (($v[0] -eq '"' -and $v[-1] -eq '"') -or ($v[0] -eq "'" -and $v[-1] -eq "'"))) {
        $v = $v.Substring(1, $v.Length - 2)
    }

    if ($v -eq 'true') { return $true }
    if ($v -eq 'false') { return $false }
    if ($v -eq 'null') { return $null }

    return $v
}

function Get-AgentSkillsSkillContent {
    <#
    .SYNOPSIS
        Loads a skill's SKILL.md from the repository and returns its parsed form.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Skill
    )

    $path = Get-AgentSkillsRepoRootRelative -RelativePath $Skill.path
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Skill '$($Skill.id)' points at a missing file: $($Skill.path)"
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $parsed = Read-AgentSkillsFrontmatter -Content $content

    return [pscustomobject]@{
        Skill       = $Skill
        Path        = $path
        Frontmatter = $parsed.Frontmatter
        Body        = $parsed.Body
        Content     = $content
        HasFrontmatter = $parsed.HasFrontmatter
    }
}
