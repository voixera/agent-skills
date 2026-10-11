# AgentSkills.psm1
# Loader. Dot-sources every Private and Public script in a deterministic order so
# that function definitions do not depend on alphabetical luck.

Set-StrictMode -Version Latest

$here = $PSScriptRoot

Get-ChildItem -LiteralPath (Join-Path $here 'Private') -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -LiteralPath (Join-Path $here 'Public') -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function @(
    'Get-AgentSkillsRegistry', 'Get-AgentSkillsRepoRoot', 'Import-AgentSkillsRegistry',
    'Get-AgentSkillsById', 'Get-AgentDefinitionById', 'Get-AgentSkillsPresetById',
    'Read-AgentSkillsJson', 'Get-AgentSkillsSchemaPath', 'Get-AgentSkillsRegistryPath',
    'Get-AgentSkillsRepoRootRelative', 'Test-AgentSkillsSchema',
    'Read-AgentSkillsFrontmatter', 'Get-AgentSkillsSkillContent',
    'Get-AgentSkillsAdapterById', 'Get-AgentSkillsSupportedFormats',
    'Get-AgentSkillsInstallPath', 'Test-AgentSkillsAgentSupportsSkill',
    'ConvertTo-AgentSkillsRenderedContent', 'New-AgentSkillsManagedBlock',
    'Merge-AgentSkillsManagedBlock', 'Remove-AgentSkillsManagedBlock',
    'Resolve-AgentSkillsSelection', 'New-AgentSkillsInstallPlan',
    'Invoke-AgentSkillsInstallPlan', 'Invoke-AgentSkillsUninstall',
    'Read-AgentSkillsManifest', 'Save-AgentSkillsManifest',
    'Get-AgentSkillsManifestPath', 'Get-AgentSkillsManifestRoot', 'Get-AgentSkillsBackupRoot',
    'Get-AgentSkillsList', 'Get-AgentSkillsAgentList', 'Get-AgentSkillsPresetList',
    'Get-AgentSkillsPresetSkills', 'Test-AgentSkillsInstallation', 'Get-AgentSkillsDoctor',
    'Invoke-AgentSkillsValidation', 'Invoke-AgentSkillsSvgValidation',
    'Test-AgentSkillsSvgWellFormed', 'Invoke-AgentSkillsSvgSecurityScan',
    'Invoke-AgentSkillsSvgAccessibilityCheck',
    'New-AgentSkillsResult', 'Write-AgentSkillsResults', 'Write-AgentSkillsMessage',
    'Test-AgentSkillsAnsiSupport', 'Get-AgentSkillsStatusVocabulary',
    'Get-AgentSkillsToolVersion', 'Get-AgentSkillsHomeDirectory',
    'Test-AgentSkillsPathInsideRoot', 'Get-AgentSkillsRelativePath'
)
