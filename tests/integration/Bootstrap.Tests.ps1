# Bootstrap.Tests.ps1
# Tests for the remote bootstrap that backs the `irm | iex` one-liner.
# Uses a local ZIP archive via AGENT_SKILLS_ARCHIVE_URL so no network is used.

Describe 'Remote bootstrap'

function New-RepoArchive {
    <#
    .SYNOPSIS
        Builds a ZIP of the current repo (excluding runtime junk) and returns its
        file:// URL, mimicking the GitHub archive layout.
    #>
    $repoRoot = Get-AgentSkillsRepoRoot
    $work = New-TestTempDirectory
    $stage = Join-Path $work 'agent-skills-main'
    New-Item -ItemType Directory -Force -Path $stage | Out-Null

    # Copy everything except runtime artifacts.
    Get-ChildItem -LiteralPath $repoRoot -Force | Where-Object {
        $_.Name -notin @('.git', '.agent-skills', 'node_modules')
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $stage -Recurse -Force
    }

    $zip = Join-Path $work 'archive.zip'
    Compress-Archive -Path $stage -DestinationPath $zip -Force
    return [pscustomobject]@{ Zip = $zip; Work = $work; Url = ('file:///' + ($zip -replace '\\', '/')) }
}

function Invoke-Bootstrap {
    param([string[]] $InstallerArgs, [string] $ArchiveUrl)
    $repoRoot = Get-AgentSkillsRepoRoot
    $script = Join-Path $repoRoot 'installer\bootstrap.ps1'
    $env:AGENT_SKILLS_NO_COLOR = '1'
    $env:AGENT_SKILLS_ARCHIVE_URL = $ArchiveUrl
    try {
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -InstallerArgs $InstallerArgs 2>&1
        return [pscustomobject]@{ Output = ($output -join "`n"); ExitCode = $LASTEXITCODE }
    } finally {
        Remove-Item Env:\AGENT_SKILLS_ARCHIVE_URL -ErrorAction SilentlyContinue
    }
}

function Test_Bootstrap_lists_skills_from_archive {
    $a = New-RepoArchive
    try {
        $r = Invoke-Bootstrap -ArchiveUrl $a.Url -InstallerArgs @('list', '-Category', 'svg')
        Assert-Equal 0 $r.ExitCode 'Bootstrap list should exit 0.'
        Assert-Match $r.Output 'svg-craft'
    } finally {
        Remove-Item -Recurse -Force $a.Work -ErrorAction SilentlyContinue
    }
}

function Test_Bootstrap_installs_into_target_project {
    $a = New-RepoArchive
    $project = New-TestTempDirectory
    try {
        $r = Invoke-Bootstrap -ArchiveUrl $a.Url -InstallerArgs @(
            'install', '-Preset', 'minimal', '-Agents', 'codex',
            '-Scope', 'project', '-Path', $project, '-Yes'
        )
        Assert-Equal 0 $r.ExitCode 'Bootstrap install should exit 0.'
        Assert-True (Test-Path (Join-Path $project '.codex\skills\code-review\SKILL.md')) 'A minimal-preset skill should be installed.'
    } finally {
        Remove-Item -Recurse -Force $a.Work -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $project -ErrorAction SilentlyContinue
    }
}

function Test_Bootstrap_rejects_placeholder_org {
    $repoRoot = Get-AgentSkillsRepoRoot
    $script = Join-Path $repoRoot 'installer\bootstrap.ps1'
    # No archive URL env, no -RepoArchiveUrl -> should throw on the placeholder.
    Remove-Item Env:\AGENT_SKILLS_ARCHIVE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:\AGENT_SKILLS_REPO_URL -ErrorAction SilentlyContinue
    Assert-Throws { & $script -InstallerArgs @('list') } 'placeholder'
}
