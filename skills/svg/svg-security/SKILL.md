---
name: svg-security
description: Treat SVG as potentially active content and reject scripts, event handlers, unsafe references, and untrusted foreignObject. Use when generating, receiving, or embedding SVG, especially SVG from an untrusted or user-controlled source.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# SVG Security

## Core principle

SVG is XML and can be active content. When opened directly in a browser or embedded
without sanitization, an SVG can execute script, load remote resources, or exfiltrate
data. Treat any SVG you did not author - and any SVG you generate from untrusted input -
as potentially hostile.

## Threat patterns to detect and reject

1. **Script elements.**
   - `<script>` anywhere in the document.
   - `<a>` with a `javascript:` href.

2. **Event-handler attributes.**
   - Any `on*` attribute (`onload`, `onclick`, `onmouseover`, `onbegin`, `onerror`, ...).
   - Including on animation elements, where handlers like `onbegin` execute.

3. **Dangerous external references.**
   - `<image href="...">` or `xlink:href` pointing at remote or unexpected URLs.
   - `<use href="external.svg#id">` referencing another document.
   - External CSS (`<?xml-stylesheet?>`), external fonts, or `<feImage>` fetching URLs.
   - Data URIs that themselves contain script-capable content.

4. **Embedded HTML / foreign content.**
   - `<foreignObject>` containing HTML (can carry scripts, forms, iframes).
   - `<iframe>`, `<embed>`, `<object>` inside the SVG.

5. **Unsafe URL schemes.**
   - `javascript:`, `data:text/html`, and `vbscript:` (obsolete but still detectable).
   - Protocol-relative or obfuscated schemes used to bypass naive checks.

6. **Untrusted content inserted without validation.** Any SVG produced by string
   concatenation with user input is a candidate for injection.

## Operating procedure

1. **Classify the source.** Authored by you and trusted vs. received/generated from an
   untrusted source. The controls below are mandatory for the latter and good hygiene
   for the former.

2. **Generate safely.** When producing SVG, do not include script, event handlers, or
   remote references at all. If content must be embedded, escape it properly.

3. **Sanitize untrusted SVG with an allow-list, in a real parser.** A regex over the
   raw text is a first-pass screen, not a guarantee. Proper handling requires parsing
   the XML and allowing only known-safe elements and attributes, ideally with a vetted
   sanitizer (e.g. DOMPurify with SVG profile) in the runtime that will host it.

4. **Serve SVG safely.** When serving user-uploaded SVG, do not serve it as
   same-origin HTML. Use `Content-Disposition: attachment` for downloads, or serve
   from a separate origin, or sanitize before serving inline. Set a restrictive
   `Content-Security-Policy` and avoid treating SVG as trusted markup.

5. **Constrain external loads.** If external references are legitimate, restrict them
   to an allow-list of origins; otherwise block them entirely.

6. **Be explicit about coverage.** State which checks ran and their limits.

## Detection: what the validator does, and does not

The bundled validator performs a heuristic scan for the patterns above (see
`installer/modules/SvgValidator.ps1`). Understand its limits:

- It is a **pattern-based screen**, useful as a first pass and for generated assets.
- It is **not** a sanitizer and **not** a guarantee of safety.
- It can miss obfuscated payloads and cannot reason about runtime hosting context.

Therefore: passing the scan means "no obvious unsafe patterns were found", not "this
SVG is safe". Never present a passing scan as proof of safety.

## Quality criteria

- No `<script>`, `on*` attributes, or `javascript:`/`vbscript:`/`data:text/html` URLs.
- No unexpected external references; `<foreignObject>` only when justified and isolated.
- Untrusted SVG is sanitized with a real parser and an allow-list before use in a page.
- Serving configuration treats uploaded SVG as untrusted content.
- The security status is reported honestly, including what was not checked.

## Anti-patterns to avoid

- `innerHTML = userProvidedSvg`.
- Serving user SVG inline from the main origin without sanitization.
- Trusting a regex sanitizer as the only defense.
- Disabling sanitization "because the SVG is simple".
- Claiming an SVG is safe because a scanner found nothing.

## Validation strategy

- Run the bundled SVG security scan and report its findings and its limitations.
- For untrusted input, confirm sanitization happens in a real XML/HTML parser with an
  allow-list, not by string replacement.
- Confirm served SVG is not treated as trusted same-origin HTML.
- Report which checks were executed and which were skipped.

## Reference

- OWASP: XSS Prevention, File Upload Security; SVG security research (script in SVG);
  DOMPurify SVG configuration.
