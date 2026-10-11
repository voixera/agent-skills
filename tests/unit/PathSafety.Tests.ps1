# PathSafety.Tests.ps1

Describe 'Path safety'

function Test_Path_inside_root_is_detected {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) 'as-root'
    $inside = Join-Path $root 'sub\file.txt'
    Assert-True (Test-AgentSkillsPathInsideRoot -Candidate $inside -Root $root) 'Path under root should be accepted.'
}

function Test_Path_traversal_is_rejected {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) 'as-root'
    $escape = Join-Path $root '..\evil\file.txt'
    Assert-False (Test-AgentSkillsPathInsideRoot -Candidate $escape -Root $root) 'Path escaping the root must be rejected.'
}

function Test_Path_sibling_of_root_is_rejected {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) 'as-root'
    $sibling = Join-Path ([System.IO.Path]::GetTempPath()) 'as-root-evil\file.txt'
    Assert-False (Test-AgentSkillsPathInsideRoot -Candidate $sibling -Root $root) 'A sibling prefix must not count as inside.'
}

function Test_Path_install_path_project_scope_uses_project_root {
    $agent = Get-AgentDefinitionById -Id 'claude-code'
    $tmp = New-TestTempDirectory
    try {
        $p = Get-AgentSkillsInstallPath -Agent $agent -SkillId 'svg-craft' -Scope project -ProjectRoot $tmp
        Assert-Match $p '\.claude[\\/]skills[\\/]svg-craft[\\/]SKILL\.md$'
        Assert-True (Test-AgentSkillsPathInsideRoot -Candidate $p -Root $tmp) 'Install path should be inside the project.'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Test_Path_install_path_user_scope_uses_home {
    $agent = Get-AgentDefinitionById -Id 'claude-code'
    $p = Get-AgentSkillsInstallPath -Agent $agent -SkillId 'svg-craft' -Scope user -ProjectRoot (Get-Location).Path
    $homeDir = Get-AgentSkillsHomeDirectory
    Assert-True ($p.StartsWith($homeDir)) 'User-scope path should start with the home directory.'
    Assert-Match $p 'skills[\\/]svg-craft[\\/]SKILL\.md$'
}
