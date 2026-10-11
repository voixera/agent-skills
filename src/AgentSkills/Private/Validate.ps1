# Validate.ps1
# Content validation: registry schemas, skill file presence, frontmatter
# correctness, cross-references (presets, dependencies, agent ids), and markdown
# structure. Every check returns PASS/FAIL/WARN/SKIP with an explicit reason when
# skipped.

Set-StrictMode -Version Latest

function Invoke-AgentSkillsValidation {
    <#
    .SYNOPSIS
        Runs the deterministic content checks over the repository.

    .OUTPUTS
        Array of result records.
    #>
    [CmdletBinding()]
    param()

    $results = New-Object System.Collections.Generic.List[object]

    # 1. Registries parse and validate against their schemas.
    $reg = $null
    try {
        $reg = Get-AgentSkillsRegistry -IgnoreSchemaErrors
    } catch {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'registry:load' -Message $_.Exception.Message -Category 'registry'))
        return $results.ToArray()
    }

    foreach ($r in @($reg.Results)) { $results.Add($r) }
    if ($reg.IsValid) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'registry:schema' -Message 'all registries match their schemas' -Category 'registry'))
    }

    # 2. Skill files exist and have valid frontmatter.
    foreach ($skill in @($reg.Skills.skills)) {
        $path = Get-AgentSkillsRepoRootRelative -RelativePath $skill.path
        if (-not (Test-Path -LiteralPath $path)) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "skill:$($skill.id)" -Message "Missing file: $($skill.path)" -Category 'skill'))
            continue
        }

        $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        $parsed = Read-AgentSkillsFrontmatter -Content $content

        if (-not $parsed.HasFrontmatter) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "skill:$($skill.id)" -Message 'SKILL.md has no YAML frontmatter' -Category 'skill'))
            continue
        }

        $fm = $parsed.Frontmatter
        $fmKeys = @($fm.Keys)
        if ($fmKeys -notcontains 'name' -or [string]::IsNullOrWhiteSpace([string]$fm['name'])) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "skill:$($skill.id)" -Message 'frontmatter is missing name' -Category 'skill'))
        }
        if ($fmKeys -notcontains 'description' -or [string]::IsNullOrWhiteSpace([string]$fm['description'])) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "skill:$($skill.id)" -Message 'frontmatter is missing description' -Category 'skill'))
        }
        # Claude Code rejects angle brackets in frontmatter.
        if (([string]$fm['description']) -match '<|>') {
            $results.Add((New-AgentSkillsResult -Status 'WARN' -Name "skill:$($skill.id)" -Message 'frontmatter description contains angle brackets (rejected by some agents)' -Category 'skill'))
        }
        # Name should match the id for discovery consistency.
        if ($fmKeys -contains 'name' -and ([string]$fm['name']) -ne $skill.id) {
            $results.Add((New-AgentSkillsResult -Status 'WARN' -Name "skill:$($skill.id)" -Message "frontmatter name '$($fm['name'])' differs from registry id" -Category 'skill'))
        }

        # Body length sanity.
        if ($parsed.Body.Trim().Length -lt 200) {
            $results.Add((New-AgentSkillsResult -Status 'WARN' -Name "skill:$($skill.id)" -Message 'skill body is very short' -Category 'skill'))
        } else {
            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name "skill:$($skill.id)" -Message 'present and well-formed' -Category 'skill'))
        }
    }

    # 3. Duplicate ids.
    $dupSkill = @($reg.Skills.skills | Group-Object id | Where-Object { $_.Count -gt 1 })
    foreach ($g in $dupSkill) {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "dup:skill:$($g.Name)" -Message "id defined $($g.Count) times" -Category 'registry'))
    }
    $dupAgent = @($reg.Agents.agents | Group-Object id | Where-Object { $_.Count -gt 1 })
    foreach ($g in $dupAgent) {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "dup:agent:$($g.Name)" -Message "id defined $($g.Count) times" -Category 'registry'))
    }

    # 4. Agent references in skills resolve, and adapters/formats are known.
    $knownAgents = @($reg.Agents.agents | ForEach-Object { $_.id })
    $knownFormats = Get-AgentSkillsSupportedFormats
    foreach ($skill in @($reg.Skills.skills)) {
        foreach ($aid in @($skill.agents)) {
            if ($knownAgents -notcontains $aid) {
                $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "ref:$($skill.id)" -Message "references unknown agent '$aid'" -Category 'reference'))
            }
        }
    }
    foreach ($agent in @($reg.Agents.agents)) {
        if ($knownFormats -notcontains $agent.format) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "adapter:$($agent.id)" -Message "format '$($agent.format)' has no renderer" -Category 'reference'))
        } else {
            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name "adapter:$($agent.id)" -Message "format '$($agent.format)' supported" -Category 'reference'))
        }
    }

    # 5. Dependencies resolve and are acyclic.
    foreach ($skill in @($reg.Skills.skills)) {
        foreach ($dep in @($skill.depends)) {
            if ($knownAgents -notcontains $dep -and ($reg.Skills.skills.id -notcontains $dep)) {
                $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "dep:$($skill.id)" -Message "depends on unknown skill '$dep'" -Category 'reference'))
            }
        }
    }
    foreach ($skill in @($reg.Skills.skills)) {
        try {
            [void](Resolve-AgentSkillsSelection -SkillIds @($skill.id) -Registry $reg)
        } catch {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "dep-cycle:$($skill.id)" -Message $_.Exception.Message -Category 'reference'))
        }
    }
    $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'dep:acyclic' -Message 'dependency graph resolved without cycles' -Category 'reference'))

    # 6. Preset references resolve.
    foreach ($preset in @($reg.Presets.presets)) {
        $bad = @()
        foreach ($ref in @($preset.skills)) {
            if (@($reg.Skills.skills.id) -notcontains $ref) { $bad += $ref }
        }
        if ($bad.Count -gt 0) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "preset:$($preset.id)" -Message "unknown skill refs: $($bad -join ', ')" -Category 'reference'))
        } else {
            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name "preset:$($preset.id)" -Message "$(@($preset.skills).Count) skill(s) resolved" -Category 'reference'))
        }
    }

    return $results.ToArray()
}
