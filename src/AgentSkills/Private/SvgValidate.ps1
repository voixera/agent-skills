# SvgValidate.ps1
# SVG validation. Deliberately reports five independent stages so that "it parses"
# is never confused with "it is safe" or "it looks right":
#   1. XML parse (well-formedness)
#   2. Security scan (scripts, event handlers, external refs, foreignObject, ...)
#   3. Accessibility (title/desc/role/aria, decorative handling) where applicable
#   4. Render (only when a renderer is available; otherwise SKIP with a reason)
#   5. Visual review (never performed automatically; always reported as not done)
#
# The security scan is pattern-based and is documented as such: it reduces risk
# and can produce false negatives. It does not "guarantee safe SVG".

Set-StrictMode -Version Latest

# Patterns that indicate potentially active or dangerous content. Kept as a
# transparent list so reviewers can audit exactly what is flagged.
$script:AgentSkillsSvgDangerPatterns = @(
    @{ Name = 'script-element';    Regex = '<\s*script[\s>]';                                       Severity = 'FAIL'; Message = '<script> element present' },
    @{ Name = 'event-handler';     Regex = '\son[a-z]+\s*=\s*["'']';                                Severity = 'FAIL'; Message = 'inline event handler attribute (on*) present' },
    @{ Name = 'javascript-url';    Regex = '(?i)(href|xlink:href)\s*=\s*["'']\s*javascript:';      Severity = 'FAIL'; Message = 'javascript: URL in a reference' },
    @{ Name = 'data-html-url';     Regex = '(?i)(href|xlink:href)\s*=\s*["'']\s*data:text/html';   Severity = 'FAIL'; Message = 'data:text/html URL in a reference' },
    @{ Name = 'foreignObject';     Regex = '<\s*foreignObject[\s>]';                                Severity = 'WARN'; Message = '<foreignObject> can embed arbitrary HTML; review carefully' },
    @{ Name = 'use-external';      Regex = '(?i)<\s*use[^>]*(href|xlink:href)\s*=\s*["''](?!#)';   Severity = 'WARN'; Message = '<use> references an external document' },
    @{ Name = 'external-entity';   Regex = '(?i)<!ENTITY';                                          Severity = 'FAIL'; Message = 'DTD entity declaration present (XXE risk)' },
    @{ Name = 'doctype';           Regex = '(?i)<!DOCTYPE[^>]*\[';                                  Severity = 'WARN'; Message = 'DOCTYPE with internal subset present' },
    @{ Name = 'remote-image';      Regex = '(?i)<\s*image[^>]*(href|xlink:href)\s*=\s*["'']\s*https?:'; Severity = 'WARN'; Message = 'remote image reference (privacy/availability)' },
    @{ Name = 'animate-to-javascript'; Regex = '(?i)<\s*(set|animate)[^>]*attributeName\s*=\s*["''](href|xlink:href)["'']'; Severity = 'WARN'; Message = 'animation targeting a URL attribute' }
)

function Test-AgentSkillsSvgWellFormed {
    <#
    .SYNOPSIS
        Attempts to parse SVG text as XML. Returns parsed bool and error message.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $SvgText)

    try {
        $doc = New-Object System.Xml.XmlDocument
        # Do NOT resolve external entities: prevents XXE during validation itself.
        $doc.XmlResolver = $null
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($SvgText)), $settings)
        try {
            $doc.Load($reader)
        } finally {
            $reader.Dispose()
        }
        return [pscustomobject]@{ Parsed = $true; Document = $doc; Error = $null }
    } catch {
        return [pscustomobject]@{ Parsed = $false; Document = $null; Error = $_.Exception.Message }
    }
}

function Invoke-AgentSkillsSvgSecurityScan {
    <#
    .SYNOPSIS
        Pattern-based security scan of SVG text. Returns result records.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $SvgText)

    $results = New-Object System.Collections.Generic.List[object]
    $findings = 0

    foreach ($p in $script:AgentSkillsSvgDangerPatterns) {
        if ($SvgText -match $p.Regex) {
            $findings++
            $results.Add((New-AgentSkillsResult -Status $p.Severity -Name "svg-security:$($p.Name)" -Message $p.Message -Category 'svg-security'))
        }
    }

    if ($findings -eq 0) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg-security' -Message 'no known unsafe patterns detected (pattern-based; not a guarantee)' -Category 'svg-security'))
    }

    return $results.ToArray()
}

function Invoke-AgentSkillsSvgAccessibilityCheck {
    <#
    .SYNOPSIS
        Checks accessible naming. A graphical SVG should have a <title> (and
        usually a <desc>); a decorative SVG should be hidden with role/aria.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SvgText,
        [switch] $RequireAccessible
    )

    $results = New-Object System.Collections.Generic.List[object]

    $hasTitle = $SvgText -match '<\s*title[\s>]'
    $hasDesc  = $SvgText -match '<\s*desc[\s>]'
    $hasRole  = $SvgText -match '(?i)role\s*=\s*["''](img|presentation)["'']'
    $ariaHidden = $SvgText -match '(?i)aria-hidden\s*=\s*["'']true["'']'
    $hasLabel = $SvgText -match '(?i)aria-label'

    if ($ariaHidden -or ($hasRole -and $SvgText -match '(?i)role\s*=\s*["'']presentation["'']')) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg-a11y' -Message 'graphic is marked decorative (aria-hidden/role=presentation)' -Category 'svg-accessibility'))
        return $results.ToArray()
    }

    if ($hasRole -and $SvgText -match '(?i)role\s*=\s*["'']img["'']' -and ($hasTitle -or $hasLabel)) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg-a11y' -Message 'role=img with a title/label present' -Category 'svg-accessibility'))
    } elseif ($hasTitle -or $hasLabel) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg-a11y' -Message 'accessible name present' -Category 'svg-accessibility'))
    } else {
        $results.Add((New-AgentSkillsResult -Status 'WARN' -Name 'svg-a11y' -Message 'no title/aria-label; add one if the graphic conveys meaning, or mark it decorative' -Category 'svg-accessibility'))
    }

    if ($hasTitle -and -not $hasDesc) {
        $results.Add((New-AgentSkillsResult -Status 'WARN' -Name 'svg-a11y:desc' -Message 'has <title> but no <desc>; consider adding one for complex graphics' -Category 'svg-accessibility'))
    }

    if ($RequireAccessible -and -not ($hasTitle -or $hasLabel) -and -not $ariaHidden) {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'svg-a11y:required' -Message 'accessible name required but missing' -Category 'svg-accessibility'))
    }

    return $results.ToArray()
}

function Invoke-AgentSkillsSvgValidation {
    <#
    .SYNOPSIS
        Full SVG validation pipeline.

    .PARAMETER Path
        Path to an SVG file.

    .PARAMETER Text
        SVG text (alternative to Path).

    .PARAMETER RequireAccessible
        Treat a missing accessible name as a failure rather than a warning.

    .PARAMETER Render
        When set and a renderer (rsvg-convert, inkscape, or a browser) is
        available, attempt to render a preview and report the outcome. Otherwise
        rendering is reported as SKIP with an explicit reason.

    .OUTPUTS
        Array of result records covering all five stages.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string] $Path,
        [Parameter(Mandatory, ParameterSetName = 'Text')]
        [string] $Text,
        [switch] $RequireAccessible,
        [switch] $Render
    )

    $results = New-Object System.Collections.Generic.List[object]

    $svgText = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -LiteralPath $Path)) {
            $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'svg:file' -Message "File not found: $Path" -Category 'svg'))
            return $results.ToArray()
        }
        $svgText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    } else {
        $svgText = $Text
    }

    # Stage 1: XML parse.
    $xml = Test-AgentSkillsSvgWellFormed -SvgText $svgText
    if ($xml.Parsed) {
        $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg:xml' -Message 'well-formed XML' -Category 'svg-parse'))
    } else {
        $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'svg:xml' -Message "XML parse error: $($xml.Error)" -Category 'svg-parse'))
        # Without a parse, deeper stages are unreliable; skip them explicitly.
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:security' -Reason 'XML did not parse' -Category 'svg-security'))
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:a11y' -Reason 'XML did not parse' -Category 'svg-accessibility'))
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:render' -Reason 'XML did not parse' -Category 'svg-render'))
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:visual-review' -Reason 'XML did not parse' -Category 'svg-visual'))
        return $results.ToArray()
    }

    # Stage 2: security.
    foreach ($r in @(Invoke-AgentSkillsSvgSecurityScan -SvgText $svgText)) { $results.Add($r) }

    # Stage 3: accessibility.
    foreach ($r in @(Invoke-AgentSkillsSvgAccessibilityCheck -SvgText $svgText -RequireAccessible:$RequireAccessible)) { $results.Add($r) }

    # Stage 4: render (optional).
    if ($Render) {
        $renderer = Get-AgentSkillsSvgRenderer
        if (-not $renderer) {
            $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:render' -Reason 'No supported renderer (rsvg-convert, inkscape, magick) found on PATH' -Category 'svg-render'))
        } else {
            try {
                $outDir = Join-Path ([System.IO.Path]::GetTempPath()) ("agentskills-svg-" + [Guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Force -Path $outDir | Out-Null
                $png = Join-Path $outDir 'preview.png'
                $args = $renderer.Arguments -replace '\{input\}', $Path -replace '\{output\}', $png
                $proc = Start-Process -FilePath $renderer.FilePath -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction Stop
                if ($proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $png)) {
                    $results.Add((New-AgentSkillsResult -Status 'PASS' -Name 'svg:render' -Message "rendered with $($renderer.Name) to $png" -Category 'svg-render'))
                } else {
                    $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'svg:render' -Message "renderer '$($renderer.Name)' exited with code $($proc.ExitCode)" -Category 'svg-render'))
                }
            } catch {
                $results.Add((New-AgentSkillsResult -Status 'FAIL' -Name 'svg:render' -Message $_.Exception.Message -Category 'svg-render'))
            }
        }
    } else {
        $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:render' -Reason 'Rendering not requested (use -Render)' -Category 'svg-render'))
    }

    # Stage 5: visual review is never automatic.
    $results.Add((New-AgentSkillsResult -Status 'SKIP' -Name 'svg:visual-review' -Reason 'Visual review is a human/AI judgement step and is never performed automatically' -Category 'svg-visual'))

    return $results.ToArray()
}

function Get-AgentSkillsSvgRenderer {
    <#
    .SYNOPSIS
        Locates an available SVG renderer. Returns $null when none is present.
    #>
    [CmdletBinding()]
    param()

    $candidates = @(
        @{ Name = 'rsvg-convert'; Exe = 'rsvg-convert'; Arguments = '--output {output} {input}' },
        @{ Name = 'inkscape';     Exe = 'inkscape';     Arguments = '--export-type=png --export-filename={output} {input}' },
        @{ Name = 'magick';       Exe = 'magick';       Arguments = '{input} {output}' }
    )

    foreach ($c in $candidates) {
        $cmd = Get-Command -Name $c.Exe -ErrorAction SilentlyContinue
        if ($cmd) {
            return [pscustomobject]@{ Name = $c.Name; FilePath = $cmd.Source; Arguments = $c.Arguments }
        }
    }
    return $null
}
