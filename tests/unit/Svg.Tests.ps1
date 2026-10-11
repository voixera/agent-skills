# Svg.Tests.ps1

Describe 'SVG validation'

$safeSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" role="img">
  <title>Check mark</title>
  <desc>A simple check mark</desc>
  <path d="M4 12l5 5L20 6" fill="none" stroke="currentColor" stroke-width="2"/>
</svg>
'@

function Test_Svg_well_formed_parses {
    $r = Test-AgentSkillsSvgWellFormed -SvgText $safeSvg
    Assert-True $r.Parsed 'Valid SVG should parse.'
}

function Test_Svg_malformed_does_not_parse {
    $r = Test-AgentSkillsSvgWellFormed -SvgText '<svg><unclosed>'
    Assert-False $r.Parsed 'Malformed SVG should fail to parse.'
}

function Test_Svg_security_detects_script_element {
    $bad = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'
    $results = @(Invoke-AgentSkillsSvgSecurityScan -SvgText $bad)
    Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' -and $_.Name -match 'script-element' }).Count -gt 0) 'Should flag <script>.'
}

function Test_Svg_security_detects_event_handler {
    $bad = '<svg xmlns="http://www.w3.org/2000/svg"><rect onclick="evil()" width="1" height="1"/></svg>'
    $results = @(Invoke-AgentSkillsSvgSecurityScan -SvgText $bad)
    Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' -and $_.Name -match 'event-handler' }).Count -gt 0) 'Should flag on* handler.'
}

function Test_Svg_security_detects_javascript_url {
    $bad = '<svg xmlns="http://www.w3.org/2000/svg"><a href="javascript:alert(1)"><text>x</text></a></svg>'
    $results = @(Invoke-AgentSkillsSvgSecurityScan -SvgText $bad)
    Assert-True (@($results | Where-Object { $_.Status -eq 'FAIL' }).Count -gt 0) 'Should flag javascript: URL.'
}

function Test_Svg_security_flags_foreignObject {
    $warn = '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject width="1" height="1"></foreignObject></svg>'
    $results = @(Invoke-AgentSkillsSvgSecurityScan -SvgText $warn)
    Assert-True (@($results | Where-Object { $_.Name -match 'foreignObject' }).Count -gt 0) 'Should flag foreignObject.'
}

function Test_Svg_security_clean_svg_passes {
    $results = @(Invoke-AgentSkillsSvgSecurityScan -SvgText $safeSvg)
    Assert-True (@($results | Where-Object { $_.Status -eq 'PASS' }).Count -gt 0) 'Clean SVG should get a security PASS.'
}

function Test_Svg_accessibility_reports_accessible_name {
    $results = @(Invoke-AgentSkillsSvgAccessibilityCheck -SvgText $safeSvg)
    Assert-True (@($results | Where-Object { $_.Status -eq 'PASS' }).Count -gt 0) 'SVG with title should pass a11y.'
}

function Test_Svg_accessibility_warns_without_name {
    $noName = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><path d="M0 0L10 10"/></svg>'
    $results = @(Invoke-AgentSkillsSvgAccessibilityCheck -SvgText $noName)
    Assert-True (@($results | Where-Object { $_.Status -eq 'WARN' }).Count -gt 0) 'Should warn about missing accessible name.'
}

function Test_Svg_accessibility_decorative_is_accepted {
    $decor = '<svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" viewBox="0 0 10 10"><path d="M0 0"/></svg>'
    $results = @(Invoke-AgentSkillsSvgAccessibilityCheck -SvgText $decor)
    Assert-True (@($results | Where-Object { $_.Status -eq 'PASS' }).Count -gt 0) 'Decorative SVG should be accepted.'
}

function Test_Svg_pipeline_reports_all_five_stages {
    $results = @(Invoke-AgentSkillsSvgValidation -Text $safeSvg)
    $categories = @($results | ForEach-Object { $_.Category })
    Assert-Contains $categories 'svg-parse' 'Should report the XML parse stage.'
    Assert-Contains $categories 'svg-security' 'Should report the security stage.'
    Assert-Contains $categories 'svg-accessibility' 'Should report the a11y stage.'
    Assert-Contains $categories 'svg-render' 'Should report the render stage.'
    Assert-Contains $categories 'svg-visual' 'Should report the visual review stage.'
}

function Test_Svg_pipeline_never_marks_visual_review_passed {
    $results = @(Invoke-AgentSkillsSvgValidation -Text $safeSvg)
    $visual = @($results | Where-Object { $_.Name -eq 'svg:visual-review' })
    Assert-Equal 'SKIP' $visual[0].Status 'Visual review must never be reported as performed.'
    Assert-True ($visual[0].Reason.Length -gt 0) 'A skip must carry a reason.'
}

function Test_Svg_pipeline_malformed_skips_deep_stages {
    $results = @(Invoke-AgentSkillsSvgValidation -Text '<svg><oops>')
    $decided = @($results | Where-Object { $_.Name -in @('svg:security', 'svg:a11y', 'svg:render', 'svg:visual-review') })
    foreach ($d in $decided) {
        Assert-True ($d.Status -in @('SKIP')) ("Expected '$($d.Name)' to be SKIP when XML is invalid, got $($d.Status).")
        Assert-True ($d.Reason.Length -gt 0) 'Skip must carry a reason.'
    }
}
