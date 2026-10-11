# Install.Tests.ps1
# Integration tests for the install/uninstall lifecycle. All work happens in
# isolated temp directories; the real user profile is never touched.

Describe 'Install lifecycle'

function Invoke-WithTempProject([scriptblock] $Body) {
    $tmp = New-TestTempDirectory
    try {
        & $Body $tmp
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Test_Install_writes_native_skill_files_for_codex_and_claude {
    Invoke-WithTempProject {
        param($tmp)
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex', 'claude-code') -Scope project -ProjectRoot $tmp
        $results = Invoke-AgentSkillsInstallPlan -Plan $plan
        Assert-Equal 0 @($results | Where-Object { $_.Status -eq 'FAIL' }).Count 'No failures expected.'
        Assert-True (Test-Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md')) 'Codex skill file should exist.'
        Assert-True (Test-Path (Join-Path $tmp '.claude\skills\svg-craft\SKILL.md')) 'Claude skill file should exist.'
    }
}

function Test_Install_writes_mdc_for_cursor {
    Invoke-WithTempProject {
        param($tmp)
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('cursor') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $plan | Out-Null
        $mdc = Join-Path $tmp '.cursor\rules\svg-craft.mdc'
        Assert-True (Test-Path $mdc) 'Cursor .mdc file should exist.'
        Assert-Match (Get-Content $mdc -Raw) 'alwaysApply: false'
    }
}

function Test_Install_manifest_is_written_and_lists_files {
    Invoke-WithTempProject {
        param($tmp)
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $plan | Out-Null
        $manifestPath = Join-Path $tmp '.agent-skills\.agent-skills-manifest.json'
        Assert-True (Test-Path $manifestPath) 'Manifest should be written.'
        $m = Read-AgentSkillsManifest -ProjectRoot $tmp -Scope project
        Assert-Equal 1 @($m.files).Count 'One file should be tracked.'
        Assert-Equal 'svg-craft' $m.files[0].skillId
        Assert-Equal 'codex' $m.files[0].agentId
    }
}

function Test_Install_is_idempotent {
    Invoke-WithTempProject {
        param($tmp)
        $a = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $a | Out-Null
        $b = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        $results = Invoke-AgentSkillsInstallPlan -Plan $b
        Assert-True (@($results | Where-Object { $_.Status -eq 'SKIP' }).Count -gt 0) 'Second install should skip unchanged files.'
    }
}

function Test_Install_verify_reports_pass_after_install {
    Invoke-WithTempProject {
        param($tmp)
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $plan | Out-Null
        $results = Test-AgentSkillsInstallation -Scope project -ProjectRoot $tmp
        Assert-Equal 0 @($results | Where-Object { $_.Status -eq 'FAIL' }).Count 'Verify should not fail.'
        Assert-Equal 0 @($results | Where-Object { $_.Status -eq 'WARN' }).Count 'Verify should not warn for an untouched install.'
    }
}

function Test_Install_conflict_detected_for_untracked_file {
    Invoke-WithTempProject {
        param($tmp)
        New-Item -ItemType Directory -Force -Path (Join-Path $tmp '.codex\skills\svg-craft') | Out-Null
        Set-Content -Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md') -Value 'user owned'
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        $results = Invoke-AgentSkillsInstallPlan -Plan $plan
        Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' -and $_.Category -eq 'conflict' }).Count -gt 0) 'Conflict should be reported.'
        Assert-Equal 'user owned' ((Get-Content (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md') -Raw).Trim()) 'User file must be untouched.'
    }
}

function Test_Install_force_overwrites_and_backs_up {
    Invoke-WithTempProject {
        param($tmp)
        New-Item -ItemType Directory -Force -Path (Join-Path $tmp '.codex\skills\svg-craft') | Out-Null
        Set-Content -Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md') -Value 'user owned'
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        $results = Invoke-AgentSkillsInstallPlan -Plan $plan -Force
        Assert-Equal 0 @($results | Where-Object { $_.Status -eq 'FAIL' }).Count 'Force install should succeed.'
        Assert-True (Test-Path (Join-Path $tmp '.agent-skills\backups\.codex\skills\svg-craft\SKILL.md')) 'Backup of the overwritten file should exist.'
    }
}

function Test_Install_uninstall_removes_only_managed_files {
    Invoke-WithTempProject {
        param($tmp)
        # A user file that must survive uninstall.
        New-Item -ItemType Directory -Force -Path (Join-Path $tmp '.codex\skills') | Out-Null
        Set-Content -Path (Join-Path $tmp '.codex\skills\user-note.md') -Value 'keep me'

        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $plan | Out-Null

        Invoke-AgentSkillsUninstall -Scope project -ProjectRoot $tmp -SkillIds @('svg-craft') | Out-Null

        Assert-False (Test-Path (Join-Path $tmp '.codex\skills\svg-craft\SKILL.md')) 'Managed file should be removed.'
        Assert-True (Test-Path (Join-Path $tmp '.codex\skills\user-note.md')) 'Untracked user file must survive.'
    }
}

function Test_Install_aggregated_block_merges_and_preserves_user_content {
    Invoke-WithTempProject {
        param($tmp)
        Set-Content -Path (Join-Path $tmp 'GEMINI.md') -Value "# Project`n`nUser instructions." -NoNewline

        $p1 = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('gemini-cli') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $p1 | Out-Null
        $p2 = New-AgentSkillsInstallPlan -SkillIds @('icon-design') -AgentIds @('gemini-cli') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $p2 | Out-Null

        $content = Get-Content (Join-Path $tmp 'GEMINI.md') -Raw
        Assert-Match $content 'User instructions' 'User content must be preserved.'
        Assert-Match $content 'SVG Craft' 'First skill should remain.'
        Assert-Match $content 'Icon Design' 'Second skill should be added.'
    }
}

function Test_Install_uninstall_one_skill_keeps_other_in_shared_block {
    Invoke-WithTempProject {
        param($tmp)
        $p1 = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('gemini-cli') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $p1 | Out-Null
        $p2 = New-AgentSkillsInstallPlan -SkillIds @('icon-design') -AgentIds @('gemini-cli') -Scope project -ProjectRoot $tmp
        Invoke-AgentSkillsInstallPlan -Plan $p2 | Out-Null

        Invoke-AgentSkillsUninstall -Scope project -ProjectRoot $tmp -SkillIds @('svg-craft') | Out-Null

        $content = Get-Content (Join-Path $tmp 'GEMINI.md') -Raw
        Assert-NotMatch $content 'SVG Craft' 'Removed skill should be gone from the block.'
        Assert-Match $content 'Icon Design' 'Remaining skill should stay in the block.'
    }
}

function Test_Install_uninstall_requires_selection {
    Invoke-WithTempProject {
        param($tmp)
        Assert-Throws { Invoke-AgentSkillsUninstall -Scope project -ProjectRoot $tmp } 'requires'
    }
}

function Test_Install_handles_path_with_spaces {
    $base = New-TestTempDirectory
    try {
        $spaced = Join-Path $base 'a folder with spaces'
        New-Item -ItemType Directory -Force -Path $spaced | Out-Null
        $plan = New-AgentSkillsInstallPlan -SkillIds @('svg-craft') -AgentIds @('codex') -Scope project -ProjectRoot $spaced
        $results = Invoke-AgentSkillsInstallPlan -Plan $plan
        Assert-Equal 0 @($results | Where-Object { $_.Status -eq 'FAIL' }).Count 'Install into a spaced path should succeed.'
        Assert-True (Test-Path (Join-Path $spaced '.codex\skills\svg-craft\SKILL.md')) 'File should exist under the spaced path.'
    } finally {
        Remove-Item -Recurse -Force $base -ErrorAction SilentlyContinue
    }
}

function Test_Install_user_scope_marker_not_in_project_only {
    # Ensures a user-scope plan does not write into the project directory.
    Invoke-WithTempProject {
        param($tmp)
        $agent = Get-AgentDefinitionById -Id 'codex'
        $userPath = Get-AgentSkillsInstallPath -Agent $agent -SkillId 'svg-craft' -Scope user -ProjectRoot $tmp
        Assert-False (Test-AgentSkillsPathInsideRoot -Candidate $userPath -Root $tmp) 'User-scope path must not be inside the project.'
    }
}
