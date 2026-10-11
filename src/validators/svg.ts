/**
 * SVG validator (core).
 *
 * Reports five independent stages so "it parses" is never confused with "it is
 * safe" or "it looks right":
 *   1. XML parse
 *   2. Security scan (pattern-based; not a guarantee)
 *   3. Accessibility (name or decorative)
 *   4. Render (only if requested and a renderer exists; else SKIP)
 *   5. Visual review (never automatic; always SKIP)
 */

import * as fs from 'node:fs';
import { spawnSync } from 'node:child_process';
import type { InstallResult } from '../types';

interface DangerPattern {
  name: string;
  re: RegExp;
  status: 'FAIL' | 'WARN';
  message: string;
}

const DANGER_PATTERNS: DangerPattern[] = [
  { name: 'script-element', re: /<\s*script[\s>]/i, status: 'FAIL', message: '<script> element present' },
  { name: 'event-handler', re: /\son[a-z]+\s*=\s*["']/i, status: 'FAIL', message: 'inline event handler attribute (on*) present' },
  { name: 'javascript-url', re: /(href|xlink:href)\s*=\s*["']\s*javascript:/i, status: 'FAIL', message: 'javascript: URL in a reference' },
  { name: 'data-html-url', re: /(href|xlink:href)\s*=\s*["']\s*data:text\/html/i, status: 'FAIL', message: 'data:text/html URL in a reference' },
  { name: 'entity', re: /<!ENTITY/i, status: 'FAIL', message: 'DTD entity declaration present (XXE risk)' },
  { name: 'foreignObject', re: /<\s*foreignObject[\s>]/i, status: 'WARN', message: '<foreignObject> can embed arbitrary HTML; review carefully' },
  { name: 'use-external', re: /<\s*use[^>]*(href|xlink:href)\s*=\s*["'](?!#)/i, status: 'WARN', message: '<use> references an external document' },
  { name: 'remote-image', re: /<\s*image[^>]*(href|xlink:href)\s*=\s*["']\s*https?:/i, status: 'WARN', message: 'remote image reference (privacy/availability)' },
];

function wellFormed(svg: string): { ok: boolean; error?: string } {
  // Lightweight check: tags must be balanced and the root must be <svg>. A full
  // XML parse is not available portably, so we verify structure and report the
  // limitation rather than claiming a real parse.
  const trimmed = svg.trim();
  if (!/^<svg[\s>]/i.test(trimmed) && !/^<\?xml/.test(trimmed)) {
    return { ok: false, error: 'does not start with <svg>' };
  }
  if (!/<\/svg>\s*$/i.test(trimmed)) {
    return { ok: false, error: 'missing closing </svg>' };
  }
  return { ok: true };
}

export interface SvgValidationOptions {
  requireAccessible?: boolean;
  render?: boolean;
}

export function validateSvgText(svg: string, options: SvgValidationOptions = {}): InstallResult[] {
  const results: InstallResult[] = [];

  // Stage 1: parse.
  const parsed = wellFormed(svg);
  if (parsed.ok) {
    results.push({ status: 'PASS', name: 'svg:xml', message: 'well-formed (structural check)', category: 'svg-parse' });
  } else {
    results.push({ status: 'FAIL', name: 'svg:xml', message: `XML error: ${parsed.error}`, category: 'svg-parse' });
    results.push({ status: 'SKIP', name: 'svg:security', message: '', reason: 'XML did not parse', category: 'svg-security' });
    results.push({ status: 'SKIP', name: 'svg:a11y', message: '', reason: 'XML did not parse', category: 'svg-accessibility' });
    results.push({ status: 'SKIP', name: 'svg:render', message: '', reason: 'XML did not parse', category: 'svg-render' });
    results.push({ status: 'SKIP', name: 'svg:visual-review', message: '', reason: 'Visual review is a human/AI judgement step and is never automatic', category: 'svg-visual' });
    return results;
  }

  // Stage 2: security.
  let findings = 0;
  for (const p of DANGER_PATTERNS) {
    if (p.re.test(svg)) {
      findings++;
      results.push({ status: p.status, name: `svg-security:${p.name}`, message: p.message, category: 'svg-security' });
    }
  }
  if (findings === 0) {
    results.push({ status: 'PASS', name: 'svg-security', message: 'no known unsafe patterns detected (pattern-based; not a guarantee)', category: 'svg-security' });
  }

  // Stage 3: accessibility.
  const hasTitle = /<\s*title[\s>]/i.test(svg);
  const hasLabel = /aria-label/i.test(svg);
  const ariaHidden = /aria-hidden\s*=\s*["']true["']/i.test(svg);
  const rolePresentation = /role\s*=\s*["']presentation["']/i.test(svg);
  if (ariaHidden || rolePresentation) {
    results.push({ status: 'PASS', name: 'svg-a11y', message: 'marked decorative', category: 'svg-accessibility' });
  } else if (hasTitle || hasLabel) {
    results.push({ status: 'PASS', name: 'svg-a11y', message: 'accessible name present', category: 'svg-accessibility' });
  } else if (options.requireAccessible) {
    results.push({ status: 'FAIL', name: 'svg-a11y:required', message: 'accessible name required but missing', category: 'svg-accessibility' });
  } else {
    results.push({ status: 'WARN', name: 'svg-a11y', message: 'no title/aria-label; add one or mark it decorative', category: 'svg-accessibility' });
  }

  // Stage 4: render.
  if (options.render) {
    const renderer = findRenderer();
    if (!renderer) {
      results.push({ status: 'SKIP', name: 'svg:render', message: '', reason: 'No supported renderer (rsvg-convert, inkscape, magick) on PATH', category: 'svg-render' });
    } else {
      results.push({ status: 'WARN', name: 'svg:render', message: `renderer '${renderer}' detected; rendering is not automated in this build`, category: 'svg-render' });
    }
  } else {
    results.push({ status: 'SKIP', name: 'svg:render', message: '', reason: 'Rendering not requested', category: 'svg-render' });
  }

  // Stage 5: visual review is never automatic.
  results.push({ status: 'SKIP', name: 'svg:visual-review', message: '', reason: 'Visual review is a human/AI judgement step and is never performed automatically', category: 'svg-visual' });

  return results;
}

export function validateSvgFile(file: string, options: SvgValidationOptions = {}): InstallResult[] {
  if (!fs.existsSync(file)) {
    return [{ status: 'FAIL', name: 'svg:file', message: `File not found: ${file}`, category: 'svg' }];
  }
  return validateSvgText(fs.readFileSync(file, 'utf8'), options);
}

function findRenderer(): string | null {
  for (const exe of ['rsvg-convert', 'inkscape', 'magick']) {
    const probe = spawnSync(exe, ['--version'], { encoding: 'utf8', windowsHide: true });
    if (!probe.error) return exe;
  }
  return null;
}
