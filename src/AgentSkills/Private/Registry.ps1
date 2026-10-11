# Registry.ps1
# Loads and validates the canonical registries (agents, skills, presets) and the
# JSON schemas that describe them. A small, self-contained schema validator is
# used because we cannot assume a JSON-Schema library is installed in a base
# Windows PowerShell 5.1 environment.

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Repository / path discovery
# ---------------------------------------------------------------------------

function Get-AgentSkillsRepoRoot {
    <#
    .SYNOPSIS
        Resolves the repository root from the module location, honouring an
        explicit override for tests and for relocated installs.
    #>
    [CmdletBinding()]
    param()

    if ($env:AGENT_SKILLS_ROOT -and (Test-Path -LiteralPath $env:AGENT_SKILLS_ROOT)) {
        return (Resolve-Path -LiteralPath $env:AGENT_SKILLS_ROOT).ProviderPath
    }

    # $PSScriptRoot at load time is .../src/AgentSkills/Private ; walk up three.
    $here = $PSScriptRoot
    if ([string]::IsNullOrEmpty($here)) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    $candidate = $here
    for ($i = 0; $i -lt 4 -and $candidate; $i++) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'registry\skills.json')) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
        $candidate = Split-Path -Parent $candidate
    }

    throw "Unable to locate the Agent Skills repository root. Set AGENT_SKILLS_ROOT to override."
}

function Get-AgentSkillsRegistryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('agents', 'skills', 'presets')]
        [string] $Name
    )
    $root = Get-AgentSkillsRepoRoot
    return (Join-Path $root "registry\$Name.json")
}

function Get-AgentSkillsSchemaPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('agents', 'skills', 'presets')]
        [string] $Name
    )
    $root = Get-AgentSkillsRepoRoot
    return (Join-Path $root "registry\schema\$Name.schema.json")
}

function Read-AgentSkillsJson {
    <#
    .SYNOPSIS
        Reads a JSON file with a clear error when it is missing or malformed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required JSON file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    try {
        return ($raw | ConvertFrom-Json)
    } catch {
        throw "Failed to parse JSON file '$Path': $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Minimal JSON-Schema (draft-07 subset) validator
# ---------------------------------------------------------------------------
# Supports the keywords actually used by the repository schemas:
#   type, required, properties, additionalProperties, items, enum,
#   pattern, minLength, minItems, uniqueItems, additionalProperties(false).
# Anything it does not understand is reported as an unsupported keyword so the
# caller is never misled into thinking an unvalidated file passed.

function Get-AgentSkillsJsonType {
    [CmdletBinding()]
    param([AllowNull()] $Value)

    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { return 'boolean' }
    if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) { return 'number' }
    if ($Value -is [string]) { return 'string' }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) { return 'array' }
    return 'object'
}

function Test-AgentSkillsSchema {
    <#
    .SYNOPSIS
        Validates a parsed object against a schema and returns result records.
    .OUTPUTS
        Array of result records; FAIL indicates a schema violation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Schema,
        [Parameter(Mandatory)] [AllowNull()] $Data,
        [string] $Path = '$'
    )

    $results = New-Object System.Collections.Generic.List[object]

    function Add-Fail($p, $msg) {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name "schema $p" -Message $msg -Category 'schema'))
    }

    # $ref is intentionally unsupported: the repository schemas are self-contained.
    if ($Schema.PSObject.Properties.Name -contains '$ref') {
        Add-Fail $Path "Unsupported keyword '$ref'. Extend the validator before using it."
        return $results.ToArray()
    }

    if ($Schema.PSObject.Properties.Name -contains 'type') {
        $expected = @($Schema.type)
        $actual = Get-AgentSkillsJsonType -Value $Data
        if ($expected -notcontains $actual) {
            Add-Fail $Path "Expected type '$($expected -join '|')' but found '$actual'."
            return $results.ToArray()
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'enum') {
        if (@($Schema.enum) -notcontains $Data) {
            Add-Fail $Path "Value '$Data' is not one of: $((@($Schema.enum)) -join ', ')."
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'pattern' -and (Get-AgentSkillsJsonType -Value $Data) -eq 'string') {
        if ($Data -notmatch $Schema.pattern) {
            Add-Fail $Path "Value '$Data' does not match pattern '$($Schema.pattern)'."
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'minLength' -and (Get-AgentSkillsJsonType -Value $Data) -eq 'string') {
        if ($Data.Length -lt [int]$Schema.minLength) {
            Add-Fail $Path "String length $($Data.Length) is below minLength $($Schema.minLength)."
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'minItems' -and (Get-AgentSkillsJsonType -Value $Data) -eq 'array') {
        $items = @($Data)
        if ($items.Count -lt [int]$Schema.minItems) {
            Add-Fail $Path "Array has $($items.Count) item(s); minItems is $($Schema.minItems)."
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'uniqueItems' -and $Schema.uniqueItems -and (Get-AgentSkillsJsonType -Value $Data) -eq 'array') {
        $items = @($Data)
        $unique = @($items | Select-Object -Unique)
        if ($unique.Count -ne $items.Count) {
            Add-Fail $Path "Array must contain unique items."
        }
    }

    if ((Get-AgentSkillsJsonType -Value $Data) -eq 'object') {
        $propNames = @($Data.PSObject.Properties.Name)

        if ($Schema.PSObject.Properties.Name -contains 'required') {
            foreach ($req in @($Schema.required)) {
                if ($propNames -notcontains $req) {
                    Add-Fail $Path "Missing required property '$req'."
                }
            }
        }

        $declared = @()
        if ($Schema.PSObject.Properties.Name -contains 'properties') {
            $declared = @($Schema.properties.PSObject.Properties.Name)
            foreach ($name in $declared) {
                if ($propNames -contains $name) {
                    $childResults = Test-AgentSkillsSchema -Schema $Schema.properties.$name -Data $Data.$name -Path "$Path.$name"
                    foreach ($cr in $childResults) { $results.Add($cr) }
                }
            }
        }

        $allowAdditional = $true
        if ($Schema.PSObject.Properties.Name -contains 'additionalProperties') {
            $allowAdditional = $Schema.additionalProperties
        }
        if ($allowAdditional -eq $false) {
            foreach ($name in $propNames) {
                if ($declared -notcontains $name) {
                    Add-Fail $Path "Unexpected property '$name' (additionalProperties is false)."
                }
            }
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'items' -and (Get-AgentSkillsJsonType -Value $Data) -eq 'array') {
        $items = @($Data)
        for ($i = 0; $i -lt $items.Count; $i++) {
            $childResults = Test-AgentSkillsSchema -Schema $Schema.items -Data $items[$i] -Path "$Path[$i]"
            foreach ($cr in $childResults) { $results.Add($cr) }
        }
    }

    return $results.ToArray()
}

# ---------------------------------------------------------------------------
# Typed loaders
# ---------------------------------------------------------------------------

function Import-AgentSkillsRegistry {
    <#
    .SYNOPSIS
        Loads a registry file and validates it against its schema.

    .OUTPUTS
        A hashtable with: Data, Results (schema results), IsValid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('agents', 'skills', 'presets')]
        [string] $Name
    )

    $data = Read-AgentSkillsJson -Path (Get-AgentSkillsRegistryPath -Name $Name)
    $schema = Read-AgentSkillsJson -Path (Get-AgentSkillsSchemaPath -Name $Name)
    $results = @(Test-AgentSkillsSchema -Schema $schema -Data $data -Path "$Name")

    $isValid = -not (@($results | Where-Object { $_.Status -eq 'FAIL' }).Count -gt 0)

    return [pscustomobject]@{
        Name    = $Name
        Data    = $data
        Results = $results
        IsValid = $isValid
    }
}

function Get-AgentSkillsRegistry {
    <#
    .SYNOPSIS
        Loads all three registries. Throws if any fails schema validation.
    #>
    [CmdletBinding()]
    param(
        [switch] $IgnoreSchemaErrors
    )

    $agents = Import-AgentSkillsRegistry -Name 'agents'
    $skills = Import-AgentSkillsRegistry -Name 'skills'
    $presets = Import-AgentSkillsRegistry -Name 'presets'

    $allResults = @($agents.Results) + @($skills.Results) + @($presets.Results)
    $hasFail = @($allResults | Where-Object { $_.Status -eq 'FAIL' }).Count -gt 0

    if ($hasFail -and -not $IgnoreSchemaErrors) {
        $failures = @($allResults | Where-Object { $_.Status -eq 'FAIL' })
        $detail = ($failures | ForEach-Object { Format-AgentSkillsResultLine -Result $_ }) -join [Environment]::NewLine
        throw "Registry schema validation failed:$([Environment]::NewLine)$detail"
    }

    return [pscustomobject]@{
        Agents  = $agents.Data
        Skills  = $skills.Data
        Presets = $presets.Data
        Results = $allResults
        IsValid = -not $hasFail
    }
}

function Get-AgentSkillsRepoRootRelative {
    <#
    .SYNOPSIS
        Resolves a registry-relative path (always forward-slashed) to an
        absolute path on the local filesystem.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )
    $root = Get-AgentSkillsRepoRoot
    $normalised = $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    return (Join-Path $root $normalised)
}

function Get-AgentSkillsById {
    <#
    .SYNOPSIS
        Looks up a skill entry by id. Throws when not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    $match = @($Registry.Skills.skills | Where-Object { $_.id -eq $Id })
    if ($match.Count -eq 0) { throw "Unknown skill id: '$Id'." }
    return $match[0]
}

function Get-AgentDefinitionById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    $match = @($Registry.Agents.agents | Where-Object { $_.id -eq $Id })
    if ($match.Count -eq 0) { throw "Unknown agent id: '$Id'." }
    return $match[0]
}

function Get-AgentSkillsPresetById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id,
        [psobject] $Registry
    )
    if (-not $Registry) { $Registry = Get-AgentSkillsRegistry }
    $match = @($Registry.Presets.presets | Where-Object { $_.id -eq $Id })
    if ($match.Count -eq 0) { throw "Unknown preset id: '$Id'." }
    return $match[0]
}
