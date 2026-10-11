# SVG quality

SVG is the project's signature feature. This page explains what "validated" means
for an SVG and, just as importantly, what it does **not** mean.

## Five independent stages

An SVG is **not** considered validated merely because it is syntactically valid.
The validator reports five stages separately so that "it parses" is never
confused with "it is safe" or "it looks right".

| Stage | Name | Status when | Notes |
| --- | --- | --- | --- |
| 1 | `svg:xml` | Parses / does not parse | Well-formedness only. |
| 2 | `svg-security*` | Clean / findings | Pattern-based; not a guarantee. |
| 3 | `svg-a11y*` | Named or decorative | Warns if a meaningful graphic has no name. |
| 4 | `svg:render` | Rendered / failed / skipped | Needs an external renderer. |
| 5 | `svg:visual-review` | **Always `SKIP`** | A human/AI judgement step; never automatic. |

If stage 1 fails, stages 2–5 are reported as `SKIP` with the reason "XML did not
parse" — because results on unparseable input would be meaningless.

## Running the validator

```powershell
.\installer\install.ps1 validate -Svg -Path .\art\logo.svg
```

Or from the module:

```powershell
Import-Module .\src\AgentSkills\AgentSkills.psd1
Invoke-AgentSkillsSvgValidation -Path .\art\logo.svg
Invoke-AgentSkillsSvgValidation -Path .\art\logo.svg -Render   # attempt a render
Invoke-AgentSkillsSvgValidation -Path .\art\logo.svg -RequireAccessible
```

## What the security scan checks

The scan is a transparent, auditable list of patterns
(`src/AgentSkills/Private/SvgValidate.ps1`, `$script:AgentSkillsSvgDangerPatterns`):

- `<script>` elements — `FAIL`.
- Inline `on*` event-handler attributes — `FAIL`.
- `javascript:` URLs in `href`/`xlink:href` — `FAIL`.
- `data:text/html` URLs — `FAIL`.
- DTD entity declarations (`<!ENTITY ...>`) — `FAIL` (XXE risk).
- `<foreignObject>` — `WARN` (can embed arbitrary HTML).
- `<use>` with an external reference — `WARN`.
- Remote `<image>` references — `WARN` (privacy/availability).
- DOCTYPE with an internal subset — `WARN`.

### This is not a security guarantee

The scan is **pattern-based**. It can miss obfuscated or novel payloads
(**false negatives**) and it can flag benign constructs (**false positives**).
Treat it as one layer, not proof. The validator itself parses XML with DTD
processing disabled and external entity resolution off, so validation does not
introduce an XXE risk.

## Rendering

`-Render` attempts a preview using the first renderer found on `PATH`:

| Renderer | Command |
| --- | --- |
| `rsvg-convert` | `rsvg-convert --output {output} {input}` |
| Inkscape | `inkscape --export-type=png --export-filename={output} {input}` |
| ImageMagick | `magick {input} {output}` |

If none is present, stage 4 is `SKIP` with that reason. A successful render means
"it produced an image", not "it looks good".

## Visual review

Visual review — composition, balance, alignment, negative space, contrast,
detail density, scalability, fidelity to the brief — is performed by a human or
an agent reading the render. The validator **never** marks it as done. Use the
`svg-visual-review` skill as the checklist.

## The SVG skills

| Skill | Purpose |
| --- | --- |
| `svg-craft` | Deliberate construction: `viewBox`, hierarchy, strokes, nodes. |
| `custom-illustration` | Plan an illustration from a brief. |
| `icon-design` | Consistent grid, silhouette, small-size legibility. |
| `logo-mark-design` | Silhouette, negative space, monochrome, scalability. |
| `svg-optimization` | Reduce size without destroying meaning. |
| `svg-accessibility` | `title`/`desc`, decorative handling, roles. |
| `svg-security` | Treat SVG as potentially active content. |
| `svg-visual-review` | Structured review against the brief. |

## Optimizing safely

Use an optimizer when available, but do not let it destroy semantics:

- Keep `title`/`desc` and `role`/`aria-*` attributes.
- Keep `viewBox`.
- Do not collapse ids that `aria-labelledby` or `<use>` reference.
- Re-run the validator after optimizing.

## Acceptance criteria

A drawing is only "done" when:

1. XML parses.
2. Security scan has no `FAIL`s (and `WARN`s were reviewed).
3. Accessibility has a name or is explicitly decorative.
4. It renders at the intended size (or rendering was explicitly skipped).
5. A visual review was performed against the brief.

Stages are reported separately so you always know which of the five actually
happened.
