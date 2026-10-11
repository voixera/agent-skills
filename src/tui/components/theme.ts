/**
 * Shared TUI presentation helpers: the logo, colour palette, section headers,
 * and the footer key-hint bar.
 *
 * Colour is applied through ANSI escapes that the inquirer-based screens already
 * support. When the host reports no colour support (NO_COLOR, or a non-TTY), we
 * fall back to plain text.
 */

import { ansiShadow } from './logo';

export const palette = {
  brand: '\u001b[36m', // cyan
  ok: '\u001b[32m', // green
  warn: '\u001b[33m', // yellow
  error: '\u001b[31m', // red
  bold: '\u001b[1m',
  dim: '\u001b[2m',
  reset: '\u001b[0m',
};

export function colorEnabled(): boolean {
  if (process.env.NO_COLOR) return false;
  if (process.env.AGENT_SKILLS_NO_COLOR) return false;
  if (process.env.FORCE_COLOR) return true;
  return Boolean(process.stdout.isTTY);
}

export function paint(text: string, color: keyof typeof palette): string {
  if (!colorEnabled()) return text;
  return `${palette[color]}${text}${palette.reset}`;
}

export function toolVersion(): string {
  try {
    // theme.js lives at dist/tui/components/, so the package root is ../../../.
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const pkg = require('../../../package.json') as { version: string };
    return pkg.version;
  } catch {
    return '0.0.0';
  }
}

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------

export function logo(): string {
  return ansiShadow('AGENT SKILLS').join('\n');
}

/** The full banner: logo, one-line description, version. */
export function banner(): string {
  const art = ansiShadow('AGENT SKILLS');
  const width = process.stdout.columns ?? 80;
  const artWidth = art[0]?.length ?? 0;

  const out: string[] = [''];
  if (width >= artWidth + 2) {
    for (const row of art) out.push('  ' + paint(row, 'brand'));
  } else {
    // Narrow terminal: a compact wordmark instead of clipped art.
    out.push('  ' + paint('A G E N T   S K I L L S', 'brand'));
  }
  out.push('');
  out.push(`  ${paint('Anti-slop rules for AI coding agents.', 'dim')}`);
  out.push(`  ${paint('Multi-agent skills manager  \u2022  v' + toolVersion(), 'dim')}`);
  out.push('');
  return out.join('\n');
}

// ---------------------------------------------------------------------------
// Section headers and key hints
// ---------------------------------------------------------------------------

/** A section header, styled like the reference installers. */
export function section(title: string, subtitle?: string): string {
  const out = [``, `  ${paint(title, 'bold')}`];
  if (subtitle) out.push(`  ${paint(subtitle, 'dim')}`);
  out.push('');
  return out.join('\n');
}

export const KEY_HINTS = {
  navigate: '\u2191/\u2193 to navigate',
  toggle: 'Space: select',
  confirm: 'Enter: confirm',
  back: 'Esc: back',
  all: 'a: all',
  quit: 'Ctrl+C: quit',
};

export function hintBar(keys: (keyof typeof KEY_HINTS)[]): string {
  const sep = paint('  \u2022  ', 'dim');
  return paint(keys.map((k) => KEY_HINTS[k]).join(sep), 'dim');
}
