# Cli.Tests.ps1
# Tests that exercise the CLI entry point as a subprocess, verifying exit codes
# and argument validation without touching the real user profile.

Describe 'CLI'

function Invoke-Cli {
    param([string[]] $Arguments)
    $repoRoot = Get-AgentSkillsRepoRoot
    $script = Join-Path $repoRoot 'installer\install.ps1'
    $psExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue)
    if (-not $psExe) { $psExe = (Get-Command pwsh.exe) }
    $env:AGENT_SKILLS_NO_COLOR = '1'
    $output = & $psExe.Source -NoProfile -ExecutionPolicy Bypass -File $script @Arguments 2>&1
    return [pscustomobject]@{ Output = ($output -join "`n"); ExitCode = $LASTEXITCODE }
}

function Test_Cli_help_exits_zero {
    $r = Invoke-Cli -Arguments @('help')
    Assert-Equal 0 $r.ExitCode 'help should exit 0.'
    Assert-Match $r.Output 'Usage:'
}

function Test_Cli_unknown_command_exits_usage_error {
    $r = Invoke-Cli -Arguments @('frobnicate')
    Assert-Equal 2 $r.ExitCode 'Unknown command should exit 2 (usage).'
}

function Test_Cli_list_exits_zero {
    $r = Invoke-Cli -Arguments @('list')
    Assert-Equal 0 $r.ExitCode 'list should exit 0.'
    Assert-Match $r.Output 'skill\(s\)'
}

function Test_Cli_validate_exits_zero_on_clean_repo {
    $r = Invoke-Cli -Arguments @('validate')
    Assert-Equal 0 $r.ExitCode 'validate should exit 0 on a clean repository.'
    Assert-Match $r.Output '0 failed'
}

function Test_Cli_install_preview_writes_nothing {
    $tmp = New-TestTempDirectory
    try {
        $r = Invoke-Cli -Arguments @('install', '-Skills', 'svg-craft', '-Agents', 'codex', '-Scope', 'project', '-Path', $tmp, '-Preview')
        Assert-Equal 0 $r.ExitCode 'preview should exit 0.'
        Assert-Match $r.Output 'Preview only'
        Assert-False (Test-Path (Join-Path $tmp '.codex')) 'Preview must not write files.'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Test_Cli_install_yes_then_uninstall {
    $tmp = New-TestTempDirectory
    try {
        $r = Invoke-Cli -Arguments @('install', '-Skills', 'svg-craft', '-Agents', 'codex', '-Scope', 'project', '-Path', $tmp, '-Yes')
        Assert-Equal 0 $r.ExitCode 'install -Yes should exit 0.'
        Assert-True (Test-Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md')) 'Skill file should be written.'

        $r2 = Invoke-Cli -Arguments @('uninstall', '-Skills', 'svg-craft', '-Scope', 'project', '-Path', $tmp)
        Assert-Equal 0 $r2.ExitCode 'uninstall should exit 0.'
        Assert-False (Test-Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md')) 'Skill file should be removed.'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Test_Cli_uninstall_without_selection_is_usage_error {
    $tmp = New-TestTempDirectory
    try {
        $r = Invoke-Cli -Arguments @('uninstall', '-Scope', 'project', '-Path', $tmp)
        Assert-Equal 2 $r.ExitCode 'uninstall with no selection should exit 2.'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Test_Cli_install_conflict_exit_code {
    $tmp = New-TestTempDirectory
    try {
        New-Item -ItemType Directory -Force -Path (Join-Path $tmp '.codex\skills\svg-craft') | Out-Null
        Set-Content -Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md') -Value 'user owned'
        $r = Invoke-Cli -Arguments @('install', '-Skills', 'svg-craft', '-Agents', 'codex', '-Scope', 'project', '-Path', $tmp, '-Yes')
        Assert-Equal 3 $r.ExitCode 'A conflict should exit 3.'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}
