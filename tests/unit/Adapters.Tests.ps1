# Adapters.Tests.ps1

Describe 'Adapter rendering'

function Get-FixturePath([string] $name) {
    $repoRoot = Get-AgentSkillsRepoRoot
    return (Join-Path $repoRoot "adapters\_fixtures\$name")
}

function Test_Adapter_skillmd_shape_matches_fixture {
    $skill = Get-AgentSkillsById -Id 'icon-design'
    $agent = Get-AgentDefinitionById -Id 'codex'
    $content = Get-AgentSkillsSkillContent -Skill $skill
    $rendered = ConvertTo-AgentSkillsRenderedContent -SkillContent $content -Agent $agent
    Assert-Match $rendered '^---'
    Assert-Match $rendered 'name: icon-design'
    Assert-Match $rendered 'category: svg'
    Assert-Match $rendered '(?m)^# Icon Design\s*$'
}

function Test_Adapter_mdc_has_cursor_frontmatter {
    $skill = Get-AgentSkillsById -Id 'icon-design'
    $agent = Get-AgentDefinitionById -Id 'cursor'
    $content = Get-AgentSkillsSkillContent -Skill $skill
    $rendered = ConvertTo-AgentSkillsRenderedContent -SkillContent $content -Agent $agent
    Assert-Match $rendered 'alwaysApply: false'
    Assert-Match $rendered 'globs:'
    Assert-Match $rendered 'description:'
}

function Test_Adapter_instructions_has_applyTo {
    $skill = Get-AgentSkillsById -Id 'icon-design'
    $agent = Get-AgentDefinitionById -Id 'github-copilot'
    $content = Get-AgentSkillsSkillContent -Skill $skill
    $rendered = ConvertTo-AgentSkillsRenderedContent -SkillContent $content -Agent $agent
    Assert-Match $rendered 'applyTo: "\*\*"'
}

function Test_Adapter_markdown_rule_has_provenance_header {
    $skill = Get-AgentSkillsById -Id 'icon-design'
    $agent = Get-AgentDefinitionById -Id 'cline'
    $content = Get-AgentSkillsSkillContent -Skill $skill
    $rendered = ConvertTo-AgentSkillsRenderedContent -SkillContent $content -Agent $agent
    Assert-Match $rendered 'Generated from the Agent Skills skill `icon-design`'
}

function Test_Adapter_all_agents_have_a_renderer {
    $reg = Get-AgentSkillsRegistry
    $known = Get-AgentSkillsSupportedFormats
    foreach ($a in @($reg.Agents.agents)) {
        Assert-Contains $known $a.format "Agent '$($a.id)' has an unknown format."
    }
}

function Test_Adapter_managed_block_merge_preserves_existing_content {
    $block = @"
<!-- agent-skills:begin -->
<!-- managed -->
content
<!-- agent-skills:end -->
"@
    $existing = "# My file`n`nkeep me`n"
    $merged = Merge-AgentSkillsManagedBlock -ExistingContent $existing -Block $block
    Assert-Match $merged 'keep me'
    Assert-Match $merged 'agent-skills:begin'
    Assert-Match $merged 'content'
}

function Test_Adapter_managed_block_replace_is_idempotent {
    $block = "<!-- agent-skills:begin -->`nA`n<!-- agent-skills:end -->"
    $first = Merge-AgentSkillsManagedBlock -ExistingContent "# Title" -Block $block
    $second = Merge-AgentSkillsManagedBlock -ExistingContent $first -Block $block
    Assert-Equal $first $second 'Re-merging identical content should be stable.'
}

function Test_Adapter_managed_block_remove_keeps_surrounding_content {
    $existing = "before`n<!-- agent-skills:begin -->`nX`n<!-- agent-skills:end -->`nafter"
    $r = Remove-AgentSkillsManagedBlock -ExistingContent $existing
    Assert-True $r.Removed 'Block should be reported as removed.'
    Assert-Equal 'beforeafter' ($r.Content -replace '\s', '')
}
