/**
 * Shared TUI presentation helpers: the logo, colour palette, and the footer
 * key-hint bar.
 *
 * Colour is applied through ANSI escapes that the inquirer-based screens
 * already support. When the host reports no colour support (NO_COLOR, or a
 * non-TTY), we fall back to plain text.
 */

export const palette = {
  brand: '\u001b[36m', // cyan
  ok: '\u001b[32m', // green
  warn: '\u001b[33m', // yellow
  error: '\u001b[31m', // red
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

/** Large ASCII-art logo, shaped to read well in monospace terminals. */
export const LOGO = String.raw`
   ___                    __     _____ __ __ _ __
  / _ | ___ ____ ___  ___ / /_   / ___// //_// //_/
 / __ |/ _ \`/ -_) _ \/ -_) __/  _\__ \/ ,<  / ,<
/_/ |_/\_, /\__/_//_/\__/\__/  /____//_/|_|/_/|_|
      /___/
`.replace(/^\n/, '');

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

export function banner(): string {
  const version = `v${toolVersion()}`;
  const lines = LOGO.split('\n').filter((l) => l.length > 0);
  const out: string[] = [''];
  for (const l of lines) out.push(paint(l, 'brand'));
  out.push('');
  out.push(`  ${paint('AGENT SKILLS', 'brand')}  ${paint(version, 'dim')}`);
  out.push(
    `  ${paint(
      'Multi-agent skills manager and anti-slop engineering toolkit.',
      'dim'
    )}`
  );
  out.push('');
  return out.join('\n');
}

export const KEY_HINTS = {
  navigate: '\u2191\u2193 navigate',
  toggle: 'space toggle',
  confirm: 'enter confirm',
  back: 'esc back',
  all: 'a select all',
  quit: 'ctrl+c quit',
};

export function hintBar(keys: (keyof typeof KEY_HINTS)[]): string {
  const sep = paint('  \u2022  ', 'dim');
  return paint(keys.map((k) => KEY_HINTS[k]).join(sep), 'dim');
}

/** A labelled section header for the non-fullscreen screens. */
export function section(title: string, subtitle?: string): string {
  const out = [`\n  ${paint(title, 'brand')}`];
  if (subtitle) out.push(`  ${paint(subtitle, 'dim')}`);
  return out.join('\n') + '\n';
}
