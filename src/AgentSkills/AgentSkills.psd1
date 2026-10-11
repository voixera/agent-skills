@{
    RootModule        = 'AgentSkills.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b7c1e2f4-3a5d-4c9e-8f10-6d2a1b0c9e77'
    Author            = 'Agent Skills contributors'
    CompanyName       = 'Agent Skills'
    Copyright         = '(c) Agent Skills contributors. MIT licensed.'
    Description       = 'Multi-agent skills manager and anti-slop engineering toolkit. Installs modular SKILL.md-based skill packs into supported AI coding agents.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Registry
        'Get-AgentSkillsRegistry', 'Get-AgentSkillsRepoRoot', 'Import-AgentSkillsRegistry',
        'Get-AgentSkillsById', 'Get-AgentDefinitionById', 'Get-AgentSkillsPresetById',
        'Read-AgentSkillsJson', 'Get-AgentSkillsSchemaPath', 'Get-AgentSkillsRegistryPath',
        'Get-AgentSkillsRepoRootRelative', 'Test-AgentSkillsSchema',
        # Content
        'Read-AgentSkillsFrontmatter', 'Get-AgentSkillsSkillContent',
        # Adapters
        'Get-AgentSkillsAdapterById', 'Get-AgentSkillsSupportedFormats',
        'Get-AgentSkillsInstallPath', 'Test-AgentSkillsAgentSupportsSkill',
        'ConvertTo-AgentSkillsRenderedContent', 'New-AgentSkillsManagedBlock',
        'Merge-AgentSkillsManagedBlock', 'Remove-AgentSkillsManagedBlock',
        # Install / uninstall
        'Resolve-AgentSkillsSelection', 'New-AgentSkillsInstallPlan',
        'Invoke-AgentSkillsInstallPlan', 'Invoke-AgentSkillsUninstall',
        # Manifest
        'Read-AgentSkillsManifest', 'Save-AgentSkillsManifest',
        'Get-AgentSkillsManifestPath', 'Get-AgentSkillsManifestRoot', 'Get-AgentSkillsBackupRoot',
        # Commands
        'Get-AgentSkillsList', 'Get-AgentSkillsAgentList', 'Get-AgentSkillsPresetList',
        'Get-AgentSkillsPresetSkills', 'Test-AgentSkillsInstallation', 'Get-AgentSkillsDoctor',
        # Validation
        'Invoke-AgentSkillsValidation', 'Invoke-AgentSkillsSvgValidation',
        'Test-AgentSkillsSvgWellFormed', 'Invoke-AgentSkillsSvgSecurityScan',
        'Invoke-AgentSkillsSvgAccessibilityCheck',
        # Logging
        'New-AgentSkillsResult', 'Write-AgentSkillsResults', 'Write-AgentSkillsMessage',
        'Test-AgentSkillsAnsiSupport', 'Get-AgentSkillsStatusVocabulary',
        # Utilities
        'Get-AgentSkillsToolVersion', 'Get-AgentSkillsHomeDirectory',
        'Test-AgentSkillsPathInsideRoot', 'Get-AgentSkillsRelativePath'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('ai', 'agents', 'skills', 'tooling', 'codex', 'claude-code', 'svg')
            ProjectUri   = 'https://github.com/voixera/agent-skills'
            LicenseUri   = 'https://github.com/voixera/agent-skills/blob/main/LICENSE'
            ReleaseNotes = 'Initial development version.'
        }
    }
}
