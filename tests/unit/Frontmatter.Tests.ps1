# Frontmatter.Tests.ps1

Describe 'Frontmatter parsing'

function Test_Frontmatter_scalars_and_nested_map {
    $yaml = @"
---
name: demo
description: A demo skill for testing frontmatter parsing.
metadata:
  category: svg
  version: 1.2.3
  agents: all
---
Body line one.
Body line two.
"@
    $parsed = Read-AgentSkillsFrontmatter -Content $yaml
    Assert-True $parsed.HasFrontmatter 'Expected frontmatter to be detected.'
    Assert-Equal 'demo' $parsed.Frontmatter['name']
    Assert-Equal 'svg' $parsed.Frontmatter['metadata']['category']
    Assert-Equal '1.2.3' $parsed.Frontmatter['metadata']['version']
    Assert-Match $parsed.Body 'Body line one\.'
}

function Test_Frontmatter_missing_delimiters_returns_no_frontmatter {
    $parsed = Read-AgentSkillsFrontmatter -Content "# Just a heading`n`nSome text."
    Assert-False $parsed.HasFrontmatter 'Should not report frontmatter when there is none.'
    Assert-Match $parsed.Body 'Just a heading'
}

function Test_Frontmatter_quotes_are_stripped {
    $yaml = "---`nname: `"quoted`"`ndescription: 'single'`n---`nbody"
    $parsed = Read-AgentSkillsFrontmatter -Content $yaml
    Assert-Equal 'quoted' $parsed.Frontmatter['name']
    Assert-Equal 'single' $parsed.Frontmatter['description']
}

function Test_SkillContent_loads_real_skill {
    $skill = Get-AgentSkillsById -Id 'icon-design'
    $content = Get-AgentSkillsSkillContent -Skill $skill
    Assert-True $content.HasFrontmatter 'Real SKILL.md should have frontmatter.'
    Assert-Equal 'icon-design' $content.Frontmatter['name']
    Assert-True ($content.Body.Length -gt 100) 'Body should be non-trivial.'
}
