# Registry.Tests.ps1

Describe 'Registry loading'

function Test_Registry_loads_and_validates {
    $reg = Get-AgentSkillsRegistry
    Assert-True $reg.IsValid 'Registry should validate against its schemas.'
    Assert-True (@($reg.Skills.skills).Count -ge 50) 'Expected at least 50 skills in the registry.'
    Assert-True (@($reg.Agents.agents).Count -ge 11) 'Expected at least 11 agents in the registry.'
    Assert-True (@($reg.Presets.presets).Count -ge 7) 'Expected at least 7 presets in the registry.'
}

function Test_Registry_skill_lookup_returns_entry {
    $skill = Get-AgentSkillsById -Id 'svg-craft'
    Assert-Equal 'svg-craft' $skill.id
    Assert-Equal 'svg' $skill.category
}

function Test_Registry_unknown_skill_lookup_throws {
    Assert-Throws { Get-AgentSkillsById -Id 'does-not-exist' } 'Unknown skill id'
}

function Test_Registry_schema_rejects_bad_object {
    # A skill missing required fields must fail validation.
    $schema = Read-AgentSkillsJson -Path (Get-AgentSkillsSchemaPath -Name 'skills')
    $bad = [pscustomobject]@{ version = '1.0.0'; skills = @([pscustomobject]@{ id = 'x' }) }
    $results = @(Test-AgentSkillsSchema -Schema $schema -Data $bad -Path 'skills')
    Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' }).Count -gt 0) 'Expected schema failures for an incomplete skill.'
}

function Test_Registry_schema_rejects_bad_id_pattern {
    $schema = Read-AgentSkillsJson -Path (Get-AgentSkillsSchemaPath -Name 'skills')
    $bad = [pscustomobject]@{ version = '1.0.0'; skills = @(
        [pscustomobject]@{
            id = 'Bad_ID'; name = 'Bad'; description = ('x' * 30); category = 'svg';
            version = '1.0.0'; path = 'x.md'; agents = @('codex')
        }
    ) }
    $results = @(Test-AgentSkillsSchema -Schema $schema -Data $bad -Path 'skills')
    Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' }).Count -gt 0) 'Expected the id pattern to be rejected.'
}

function Test_Registry_every_skill_file_exists {
    $reg = Get-AgentSkillsRegistry
    $missing = @()
    foreach ($s in @($reg.Skills.skills)) {
        $p = Get-AgentSkillsRepoRootRelative -RelativePath $s.path
        if (-not (Test-Path -LiteralPath $p)) { $missing += $s.id }
    }
    Assert-Equal 0 $missing.Count ("Missing skill files: " + ($missing -join ', '))
}
