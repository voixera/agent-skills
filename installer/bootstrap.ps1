<#
.SYNOPSIS
    Agent Skills remote bootstrap.

.DESCRIPTION
    Downloads the Agent Skills repository as a ZIP archive and runs the installer
    from a temporary location. Intended to be invoked through the one-line
    bootstrap published in the README (see below). It does not install anything
    system-wide by itself and it does not require administrator rights.

    Because a remote one-liner runs code from the internet, the recommended flow
    is:
      1. Inspect what you are about to run (save it first, then read it).
      2. Run it.
    See docs/installation.md, "Remote bootstrap (irm | iex)" for the safe pattern.

.PARAMETER RepoArchiveUrl
    URL of the repository ZIP archive. Defaults to the main branch archive.

.PARAMETER Ref
    Branch, tag, or commit to download. Defaults to 'main'.

.PARAMETER InstallerArgs
    Additional arguments forwarded to installer/install.ps1.

.PARAMETER Keep
    Do not delete the temporary extraction directory after the installer runs.

.EXAMPLE
    # Download + run the interactive installer
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/<your-org>/agent-skills/main/installer/bootstrap.ps1)))

.EXAMPLE
    # Non-interactive
    $env:AGENT_SKILLS_BOOTSTRAP_ARGS = 'install -Preset minimal -Agents claude-code -Yes'
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/<your-org>/agent-skills/main/installer/bootstrap.ps1)))
#>
[CmdletBinding()]
param(
    [string] $RepoArchiveUrl,
    [string] $Ref = 'main',
    [string[]] $InstallerArgs,
    [switch] $Keep
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Resolve the archive URL.
# Override with -RepoArchiveUrl, or the AGENT_SKILLS_ARCHIVE_URL env var, so
# forks and pinned refs work without editing this file.
# ---------------------------------------------------------------------------
if (-not $RepoArchiveUrl) {
    if ($env:AGENT_SKILLS_REPO_URL) {
        # Expecting shape: https://github.com/<owner>/<repo>
        $RepoArchiveUrl = ($env:AGENT_SKILLS_REPO_URL.TrimEnd('/')) + "/archive/refs/heads/$Ref.zip"
    } elseif ($env:AGENT_SKILLS_ARCHIVE_URL) {
        $RepoArchiveUrl = $env:AGENT_SKILLS_ARCHIVE_URL
    } else {
        # Placeholder: replace <your-org> after publishing. Intentionally obvious.
        $RepoArchiveUrl = "https://github.com/<your-org>/agent-skills/archive/refs/heads/$Ref.zip"
    }
}

if ($RepoArchiveUrl -match '<your-org>') {
    throw "The repository URL is still the placeholder '<your-org>'. Publish the repo and replace it, or pass -RepoArchiveUrl."
}

function Write-Step([string] $Message) {
    Write-Host "[agent-skills] $Message" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Download and extract.
# ---------------------------------------------------------------------------
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-skills-bootstrap-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null

try {
    $zipPath = Join-Path $workRoot 'agent-skills.zip'

    Write-Step "Downloading $RepoArchiveUrl"
    $progressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $RepoArchiveUrl -OutFile $zipPath -UseBasicParsing

    Write-Step "Extracting"
    Expand-Archive -LiteralPath $zipPath -DestinationPath $workRoot -Force

    # The archive extracts to a single top-level folder, e.g. agent-skills-main.
    $extracted = Get-ChildItem -LiteralPath $workRoot -Directory | Select-Object -First 1
    if (-not $extracted) {
        throw "The downloaded archive did not contain a project folder."
    }

    $installer = Join-Path $extracted.FullName 'installer\install.ps1'
    if (-not (Test-Path -LiteralPath $installer)) {
        throw "Could not find installer/install.ps1 inside the downloaded archive."
    }

    # Forward arguments. If none were passed positionally, allow the environment
    # variable (useful for the one-liner form).
    if (-not $InstallerArgs -and $env:AGENT_SKILLS_BOOTSTRAP_ARGS) {
        $InstallerArgs = @($env:AGENT_SKILLS_BOOTSTRAP_ARGS -split '\s+' | Where-Object { $_ -ne '' })
    }

    Write-Step "Running the installer from $($extracted.FullName)"
    Write-Host ''

    if ($InstallerArgs -and $InstallerArgs.Count -gt 0) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer @InstallerArgs
    } else {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
    }
    $exitCode = $LASTEXITCODE

    if ($Keep) {
        Write-Step "Kept the working directory: $($extracted.FullName)"
    }

    exit $exitCode
} finally {
    if (-not $Keep) {
        Remove-Item -Recurse -Force $workRoot -ErrorAction SilentlyContinue
    }
}
