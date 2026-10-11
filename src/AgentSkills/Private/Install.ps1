# Install.ps1
# The installation planner and executor. Planning is pure (no writes); execution
# performs the writes described by a plan. Keeping them separate is what makes
# `--preview` trustworthy.

Set-StrictMode -Version Latest

function Resolve-AgentSkillsSelection {
    <#
    .SYNOPSIS
        Resolves a set of requested skill ids into a concrete, dependency-closed
        set, reporting which dependency skills were pulled in.

    .DESCRIPTION
        Dependencies are resolved using the `depends` field in skills.json. Cycles
        are detected and reported as an error. The user is told exactly which
        extra skills were added.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]] $SkillIds,
        [psobject] $Registry
    )

    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }

    $requested = New-Object System.Collections.Generic.HashSet[string]
    foreach ($id in $SkillIds) { [void]$requested.Add($id) }

    $resolved = New-Object System.Collections.Generic.HashSet[string]
    $addedDependencies = New-Object System.Collections.Generic.List[string]
    $stack = New-Object System.Collections.Generic.Stack[string]
    $inStack = New-Object System.Collections.Generic.HashSet[string]

    foreach ($id in $requested) { $stack.Push($id) }

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $skill = Get-AgentSkillsById -Id $current -Registry $Registry  # throws if unknown

        if ($inStack.Contains($current)) {
            throw "Circular dependency detected involving skill '$current'."
        }
        if ($resolved.Contains($current)) { continue }

        $inStack.Add($current) | Out-Null
        foreach ($dep in @($skill.depends)) {
            if ([string]::IsNullOrWhiteSpace($dep)) { continue }
            if (-not $resolved.Contains($dep)) { $stack.Push($dep) }
        }
        $inStack.Remove($current) | Out-Null

        $resolved.Add($current) | Out-Null
        if (-not $requested.Contains($current)) { $addedDependencies.Add($current) }
    }

    return [pscustomobject]@{
        Requested        = @($requested)
        Resolved         = @($resolved)
        AddedDependencies = @($addedDependencies)
    }
}

function New-AgentSkillsInstallPlan {
    <#
    .SYNOPSIS
        Builds a read-only plan describing every file that install would write.

    .PARAMETER SkillIds
        Requested skill ids.

    .PARAMETER AgentIds
        Requested agent ids.

    .PARAMETER Scope
        project or user.

    .PARAMETER ProjectRoot
        The project directory (used for project scope).

    .PARAMETER IncludeDependencies
        When set (default), pull in skill dependencies.

    .OUTPUTS
        A plan object with Actions (per file) and diagnostics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]] $SkillIds,
        [Parameter(Mandatory)] [string[]] $AgentIds,
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [switch] $IncludeDependencies,
        [psobject] $Registry
    )

    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }

    $includeDeps = $true
    if ($PSBoundParameters.ContainsKey('IncludeDependencies')) {
        $includeDeps = [bool]$IncludeDependencies
    }

    if ($includeDeps) {
        $selection = Resolve-AgentSkillsSelection -SkillIds $SkillIds -Registry $Registry
    } else {
        foreach ($id in $SkillIds) { [void](Get-AgentSkillsById -Id $id -Registry $Registry) }
        $selection = [pscustomobject]@{ Requested = $SkillIds; Resolved = $SkillIds; AddedDependencies = @() }
    }

    $scopeRoot = if ($Scope -eq 'user') { Get-AgentSkillsHomeDirectory } else { (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath }

    $actions = New-Object System.Collections.Generic.List[object]
    $diagnostics = New-Object System.Collections.Generic.List[object]

    # Existing manifest lets aggregated blocks accumulate across separate install
    # runs instead of replacing each other.
    $existingManifest = Read-AgentSkillsManifest -ProjectRoot $ProjectRoot -Scope $Scope
    $existingManagedByPath = @{}
    foreach ($f in @($existingManifest.files)) {
        if ($f.action -eq 'managed-block') {
            $ids = @()
            if ($f.PSObject.Properties.Name -contains 'skillIds' -and $f.skillIds) {
                $ids = @($f.skillIds)
            } elseif ($f.skillId) {
                $ids = @($f.skillId -split ',\s*')
            }
            $existingManagedByPath[$f.path] = $ids
        }
    }

    # Aggregated-instruction agents accumulate here so a single file is written once.
    $aggregated = @{}

    foreach ($skillId in $selection.Resolved) {
        $skill = Get-AgentSkillsById -Id $skillId -Registry $Registry

        foreach ($agentId in $AgentIds) {
            $agent = Get-AgentDefinitionById -Id $agentId -Registry $Registry

            if (-not (Test-AgentSkillsAgentSupportsSkill -Skill $skill -Agent $agent)) {
                $diagnostics.Add((New-AgentSkillsResult -Status 'WARN' -Name "compat $skillId/$agentId" `
                    -Message "Skill '$skillId' does not list agent '$agentId' as supported; it will be skipped." -Category 'compatibility'))
                continue
            }

            if (@($agent.scopes) -notcontains $Scope) {
                $diagnostics.Add((New-AgentSkillsResult -Status 'WARN' -Name "scope $skillId/$agentId" `
                    -Message "Agent '$agentId' does not support scope '$Scope'; it will be skipped." -Category 'compatibility'))
                continue
            }

            $destination = Get-AgentSkillsInstallPath -Agent $agent -SkillId $skillId -Scope $Scope -ProjectRoot $ProjectRoot

            if (-not (Test-AgentSkillsPathInsideRoot -Candidate $destination -Root $scopeRoot)) {
                $diagnostics.Add((New-AgentSkillsResult -Status 'FAIL' -Name "traversal $skillId/$agentId" `
                    -Message "Resolved path escapes the selected scope: $destination" -Category 'safety'))
                continue
            }

            $skillContent = Get-AgentSkillsSkillContent -Skill $skill

            if ($agent.format -eq 'aggregated-instructions') {
                if (-not $aggregated.ContainsKey($destination)) {
                    $aggregated[$destination] = [pscustomobject]@{
                        Agent         = $agent
                        Destination   = $destination
                        SkillContents = New-Object System.Collections.Generic.List[object]
                        SkillIds      = New-Object System.Collections.Generic.List[string]
                    }
                    # Seed with skills already installed for this destination.
                    if ($existingManagedByPath.ContainsKey($destination)) {
                        foreach ($existingId in @($existingManagedByPath[$destination])) {
                            if ([string]::IsNullOrWhiteSpace($existingId)) { continue }
                            if ($selection.Resolved -notcontains $existingId) {
                                try {
                                    $existingSkill = Get-AgentSkillsById -Id $existingId -Registry $Registry
                                    $aggregated[$destination].SkillContents.Add((Get-AgentSkillsSkillContent -Skill $existingSkill)) | Out-Null
                                    $aggregated[$destination].SkillIds.Add($existingId) | Out-Null
                                } catch {
                                    # A previously installed skill no longer in the registry: keep the id
                                    # so uninstall can still clean it up, but do not fail the install.
                                    $diagnostics.Add((New-AgentSkillsResult -Status 'WARN' -Name "existing:$existingId" `
                                        -Message "Previously installed skill '$existingId' is no longer in the registry; it will be preserved." -Category 'compatibility'))
                                }
                            }
                        }
                    }
                }
                $aggregated[$destination].SkillContents.Add($skillContent) | Out-Null
                if (-not $aggregated[$destination].SkillIds.Contains($skillId)) {
                    $aggregated[$destination].SkillIds.Add($skillId) | Out-Null
                }
                continue
            }

            $newContent = ConvertTo-AgentSkillsRenderedContent -SkillContent $skillContent -Agent $agent
            $state = Get-AgentSkillsFileState -Path $destination -NewContent $newContent

            $action = if (-not $state.Exists) { 'create' }
                      elseif ($state.Identical) { 'unchanged' }
                      else { 'overwrite' }

            $actions.Add([pscustomobject]@{
                Kind        = 'file'
                AgentId     = $agentId
                SkillId     = $skillId
                SkillVersion = $skill.version
                Destination = $destination
                RelativePath = Get-AgentSkillsRelativePath -Path $destination -Root $scopeRoot
                Action      = $action
                Format      = $agent.format
                Content     = $newContent
                ExistingHash = $state.Hash
            }) | Out-Null
        }
    }

    # Materialise aggregated blocks.
    foreach ($key in $aggregated.Keys) {
        $entry = $aggregated[$key]
        $block = New-AgentSkillsManagedBlock -SkillContents $entry.SkillContents.ToArray() -ToolVersion (Get-AgentSkillsToolVersion)
        $existing = if (Test-Path -LiteralPath $entry.Destination) { Get-Content -LiteralPath $entry.Destination -Raw -Encoding UTF8 } else { $null }
        $merged = Merge-AgentSkillsManagedBlock -ExistingContent $existing -Block $block

        $action = if ($null -eq $existing) { 'create' }
                  elseif ($existing -eq $merged) { 'unchanged' }
                  else { 'overwrite' }

        $actions.Add([pscustomobject]@{
            Kind         = 'managed-block'
            AgentId      = $entry.Agent.id
            SkillId      = ($entry.SkillIds.ToArray() -join ', ')
            SkillIds     = $entry.SkillIds.ToArray()
            SkillVersion = ''
            Destination  = $entry.Destination
            RelativePath = Get-AgentSkillsRelativePath -Path $entry.Destination -Root $scopeRoot
            Action       = $action
            Format       = $entry.Agent.format
            Content      = $merged
            ExistingHash = $null
        }) | Out-Null
    }

    return [pscustomobject]@{
        Scope        = $Scope
        ProjectRoot  = $ProjectRoot
        ScopeRoot    = $scopeRoot
        Agents       = $AgentIds
        Requested    = $selection.Requested
        Resolved     = $selection.Resolved
        AddedDependencies = $selection.AddedDependencies
        Actions      = $actions.ToArray()
        Diagnostics  = $diagnostics.ToArray()
    }
}

function Invoke-AgentSkillsInstallPlan {
    <#
    .SYNOPSIS
        Executes a plan produced by New-AgentSkillsInstallPlan.

    .PARAMETER Plan
        The plan to execute.

    .PARAMETER Force
        Overwrite files that are not tracked by the manifest (a conflict) without
        prompting. Without it, conflicts are reported and skipped.

    .PARAMETER WhatIf
        When set, no writes occur; the intended actions are returned.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Plan,
        [switch] $Force,
        [switch] $WhatIf
    )

    $manifest = Read-AgentSkillsManifest -ProjectRoot $Plan.ProjectRoot -Scope $Plan.Scope
    $backupRoot = Get-AgentSkillsBackupRoot -ProjectRoot $Plan.ProjectRoot -Scope $Plan.Scope
    $results = New-Object System.Collections.Generic.List[object]

    $existingByPath = @{}
    foreach ($f in @($manifest.files)) { $existingByPath[$f.path] = $f }

    $newEntries = New-Object System.Collections.Generic.List[object]
    # Preserve entries not being touched.
    $touchedPaths = @($Plan.Actions | ForEach-Object { $_.Destination })
    foreach ($f in @($manifest.files)) {
        if ($touchedPaths -notcontains $f.path) { $newEntries.Add($f) | Out-Null }
    }

    foreach ($action in $Plan.Actions) {
        if ($action.Action -eq 'unchanged') {
            $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name $action.RelativePath -Reason 'Already up to date' -Category 'install'))
            # Keep the existing manifest entry.
            if ($existingByPath.ContainsKey($action.Destination)) { $newEntries.Add($existingByPath[$action.Destination]) | Out-Null }
            continue
        }

        $isConflict = $false
        if ($action.Action -eq 'overwrite' -and $action.Kind -ne 'managed-block') {
            # Managed-block merges are non-destructive (only our delimited block
            # is touched), so a pre-existing file is not a conflict for them.
            $tracked = $existingByPath.ContainsKey($action.Destination)
            if (-not $tracked) { $isConflict = $true }
        }

        if ($isConflict -and -not $Force) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name $action.RelativePath `
                -Message 'Existing untracked file; rerun with -Force to overwrite (a backup will be made).' -Category 'conflict'))
            continue
        }

        if ($WhatIf) {
            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $action.RelativePath -Message "Would $($action.Action)." -Category 'install'))
            continue
        }

        try {
            $backupPath = $null
            if ($action.Action -eq 'overwrite') {
                $backupPath = Backup-AgentSkillsFile -Path $action.Destination -BackupRoot $backupRoot -ScopeRoot $Plan.ScopeRoot
            }

            Write-AgentSkillsFile -Path $action.Destination -Content $action.Content -Root $Plan.ScopeRoot

            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $action.RelativePath -Message $action.Action -Category 'install'))

            $manifestAction = 'modified'
            if ($action.Action -eq 'create') { $manifestAction = 'created' }
            elseif ($action.Kind -eq 'managed-block') { $manifestAction = 'managed-block' }

            $actionSkillIds = @()
            if ($action.PSObject.Properties.Name -contains 'SkillIds' -and $action.SkillIds) {
                $actionSkillIds = @($action.SkillIds)
            }

            $newEntries.Add((New-AgentSkillsManifestEntry `
                -Path $action.Destination `
                -RelativePath $action.RelativePath `
                -SkillId $action.SkillId `
                -AgentId $action.AgentId `
                -SkillVersion $action.SkillVersion `
                -Scope $Plan.Scope `
                -Action $manifestAction `
                -Backup $backupPath `
                -SkillIds $actionSkillIds `
                -Hash (Get-AgentSkillsStringHash -Text $action.Content))) | Out-Null
        } catch {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name $action.RelativePath -Message $_.Exception.Message -Category 'install'))
        }
    }

    if (-not $WhatIf) {
        $finalManifest = New-AgentSkillsManifest -Scope $Plan.Scope -Files $newEntries.ToArray()
        Save-AgentSkillsManifest -Manifest $finalManifest -ProjectRoot $Plan.ProjectRoot -Scope $Plan.Scope | Out-Null
    }

    return $results.ToArray()
}

function Invoke-AgentSkillsUninstall {
    <#
    .SYNOPSIS
        Removes installed files tracked in the manifest for the given skills
        and/or agents. Files not tracked are never touched.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('project', 'user')] [string] $Scope,
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [string[]] $SkillIds,
        [string[]] $AgentIds,
        [switch] $All,
        [switch] $WhatIf,
        [psobject] $Registry
    )

    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }

    $manifest = Read-AgentSkillsManifest -ProjectRoot $ProjectRoot -Scope $Scope
    $scopeRoot = if ($Scope -eq 'user') { Get-AgentSkillsHomeDirectory } else { (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath }

    $entries = @($manifest.files)
    $results = New-Object System.Collections.Generic.List[object]
    $toKeep = New-Object System.Collections.Generic.List[object]

    if (-not $All -and -not $SkillIds -and -not $AgentIds) {
        throw "Uninstall requires -All or at least one -SkillIds/-AgentIds selection."
    }

    # Which ids are we removing?
    $removeSkillSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($s in @($SkillIds)) { if ($s) { [void]$removeSkillSet.Add($s) } }
    $removeAgentSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($a in @($AgentIds)) { if ($a) { [void]$removeAgentSet.Add($a) } }

    foreach ($e in $entries) {
        $entrySkillIds = @()
        if ($e.PSObject.Properties.Name -contains 'skillIds' -and $e.skillIds) {
            $entrySkillIds = @($e.skillIds)
        } elseif ($e.skillId) {
            $entrySkillIds = @($e.skillId -split ',\s*')
        }

        $agentMatches = ($removeAgentSet.Count -eq 0) -or $removeAgentSet.Contains($e.agentId)

        if ($All) {
            $remainingSkillIds = @()
        } elseif ($e.action -eq 'managed-block') {
            # Remove only the selected ids; keep the rest inside the block.
            $remainingSkillIds = @($entrySkillIds | Where-Object { -not $removeSkillSet.Contains($_) })
            if ($removeSkillSet.Count -gt 0 -and $entrySkillIds.Count -gt 0 -and
                $remainingSkillIds.Count -eq $entrySkillIds.Count) {
                # Nothing in this block was selected for removal.
                $toKeep.Add($e) | Out-Null
                continue
            }
        } else {
            $selected = $false
            foreach ($sid in $entrySkillIds) { if ($removeSkillSet.Contains($sid)) { $selected = $true; break } }
            if (-not $selected -or -not $agentMatches) {
                $toKeep.Add($e) | Out-Null
                continue
            }
            $remainingSkillIds = @()
        }

        # --- Managed block that still has survivors: regenerate in place. ---
        if ($e.action -eq 'managed-block' -and $remainingSkillIds.Count -gt 0) {
            if ($WhatIf) {
                $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $e.relativePath -Message "Would update block (keep: $($remainingSkillIds -join ', '))." -Category 'uninstall'))
                continue
            }
            try {
                $survivors = New-Object System.Collections.Generic.List[object]
                foreach ($sid in $remainingSkillIds) {
                    $s = Get-AgentSkillsById -Id $sid -Registry $Registry
                    $survivors.Add((Get-AgentSkillsSkillContent -Skill $s)) | Out-Null
                }
                $block = New-AgentSkillsManagedBlock -SkillContents $survivors.ToArray() -ToolVersion (Get-AgentSkillsToolVersion)
                $existing = if (Test-Path -LiteralPath $e.path) { Get-Content -LiteralPath $e.path -Raw -Encoding UTF8 } else { $null }
                $merged = Merge-AgentSkillsManagedBlock -ExistingContent $existing -Block $block
                Write-AgentSkillsFile -Path $e.path -Content $merged -Root $scopeRoot
                $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $e.relativePath -Message "block updated (kept: $($remainingSkillIds -join ', '))" -Category 'uninstall'))

                $keptEntry = New-AgentSkillsManifestEntry -Path $e.path -RelativePath $e.relativePath `
                    -SkillId ($remainingSkillIds -join ', ') -AgentId $e.agentId -SkillVersion '' `
                    -Scope $Scope -Action 'managed-block' -SkillIds $remainingSkillIds `
                    -Hash (Get-AgentSkillsStringHash -Text $merged)
                $toKeep.Add($keptEntry) | Out-Null
            } catch {
                $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name $e.relativePath -Message $_.Exception.Message -Category 'uninstall'))
                $toKeep.Add($e) | Out-Null
            }
            continue
        }

        # --- Whole-file removal (or managed block emptied). ---
        if ($WhatIf) {
            $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $e.relativePath -Message 'Would remove.' -Category 'uninstall'))
            continue
        }

        try {
            if (Test-Path -LiteralPath $e.path) {
                Remove-AgentSkillsFileIfManaged -Path $e.path -Root $scopeRoot | Out-Null
                $results.Add((New-AgentSkillsResult -Status 'PASS' -Name $e.relativePath -Message 'removed' -Category 'uninstall'))
                Remove-AgentSkillsEmptyDirectories -StartDirectory (Split-Path -Parent $e.path) -Root $scopeRoot
            } else {
                $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name $e.relativePath -Reason 'Already absent' -Category 'uninstall'))
            }
        } catch {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name $e.relativePath -Message $_.Exception.Message -Category 'uninstall'))
        }
    }

    if (-not $WhatIf) {
        $finalManifest = New-AgentSkillsManifest -Scope $Scope -Files $toKeep.ToArray()
        Save-AgentSkillsManifest -Manifest $finalManifest -ProjectRoot $ProjectRoot -Scope $Scope | Out-Null
    }

    return $results.ToArray()
}
