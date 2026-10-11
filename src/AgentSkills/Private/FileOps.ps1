# FileOps.ps1
# Safe filesystem primitives. Everything that writes to disk goes through here so
# that previews, conflict detection, backups, and the manifest stay consistent.

Set-StrictMode -Version Latest

function Test-AgentSkillsPathInsideRoot {
    <#
    .SYNOPSIS
        Returns $true when Candidate resolves to a location inside Root.

    .DESCRIPTION
        Guards against path traversal: a destination that escapes the selected
        scope must never be written.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Candidate,
        [Parameter(Mandatory)] [string] $Root
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    # Normalise the candidate's parent because the leaf may not exist yet.
    $candidateFull = [System.IO.Path]::GetFullPath($Candidate)

    if ($candidateFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }

    $rootWithSep = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-AgentSkillsRelativePath {
    <#
    .SYNOPSIS
        Returns Path relative to Root (forward slashes), for manifests/logs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Root
    )
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $pathFull.Substring($rootFull.Length).TrimStart('\', '/')
        return ($rel -replace '\\', '/')
    }
    return $pathFull
}

function Get-AgentSkillsFileState {
    <#
    .SYNOPSIS
        Describes whether a destination exists and how it compares to new content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowNull()] [string] $NewContent
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Exists = $false; Identical = $false; Hash = $null }
    }

    $existing = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $identical = ($existing -eq $NewContent)
    return [pscustomobject]@{
        Exists    = $true
        Identical = $identical
        Hash      = Get-AgentSkillsStringHash -Text $existing
    }
}

function Get-AgentSkillsStringHash {
    [CmdletBinding()]
    param([AllowNull()] [string] $Text)
    if ($null -eq $Text) { return $null }
    # Normalise line endings so a file written with LF and read back with CRLF on
    # Windows does not register as tampering.
    $normalised = $Text -replace "`r`n", "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalised)
        $hash = $sha.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
    } finally {
        $sha.Dispose()
    }
}

function Write-AgentSkillsFile {
    <#
    .SYNOPSIS
        Writes content to a file, creating parent directories as needed, using
        UTF-8 without a BOM and LF line endings (respecting .gitattributes intent).

    .PARAMETER Path
        Destination path.

    .PARAMETER Content
        Content to write.

    .PARAMETER Root
        If supplied, the destination must resolve inside this root or the write
        is refused.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Content,
        [string] $Root
    )

    if ($Root -and -not (Test-AgentSkillsPathInsideRoot -Candidate $Path -Root $Root)) {
        throw "Refusing to write outside the selected scope: $Path"
    }

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Backup-AgentSkillsFile {
    <#
    .SYNOPSIS
        Copies an existing file into the backup directory, preserving a relative
        path so restores are unambiguous. Returns the backup path or $null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $BackupRoot,
        [Parameter(Mandatory)] [string] $ScopeRoot
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    $rel = Get-AgentSkillsRelativePath -Path $Path -Root $ScopeRoot
    $dest = Join-Path $BackupRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $destDir = Split-Path -Parent $dest
    if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }
    Copy-Item -LiteralPath $Path -Destination $dest -Force
    return $dest
}

function Remove-AgentSkillsFileIfManaged {
    <#
    .SYNOPSIS
        Deletes a file only when it is tracked in the manifest. Never removes
        something the tool did not create.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Root
    )

    if (-not (Test-AgentSkillsPathInsideRoot -Candidate $Path -Root $Root)) {
        throw "Refusing to delete outside the selected scope: $Path"
    }
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
        return $true
    }
    return $false
}

function Remove-AgentSkillsEmptyDirectories {
    <#
    .SYNOPSIS
        Removes now-empty directories up to (but not including) Root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $StartDirectory,
        [Parameter(Mandatory)] [string] $Root
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $dir = [System.IO.Path]::GetFullPath($StartDirectory)

    while ($dir -and -not $dir.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        if (-not (Test-Path -LiteralPath $dir)) { break }
        $children = @(Get-ChildItem -LiteralPath $dir -Force)
        if ($children.Count -gt 0) { break }
        Remove-Item -LiteralPath $dir -Force
        $dir = Split-Path -Parent $dir
    }
}

function Get-AgentSkillsTimestamp {
    [CmdletBinding()]
    param()
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Get-AgentSkillsToolVersion {
    <#
    .SYNOPSIS
        Reads the toolkit version from the module manifest so the manifest and
        the managed blocks stay in sync.
    #>
    [CmdletBinding()]
    param()
    $root = Get-AgentSkillsRepoRoot
    $manifest = Join-Path $root 'src\AgentSkills\AgentSkills.psd1'
    if (Test-Path -LiteralPath $manifest) {
        $data = Import-PowerShellDataFile -LiteralPath $manifest
        return $data.ModuleVersion
    }
    return '0.0.0'
}
