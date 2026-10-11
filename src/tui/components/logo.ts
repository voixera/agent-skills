/**
 * BIG.LOGO - ANSI-shadow wordmark for the TUI.
 *
 * Renders "AGENT SKILLS" as the classic ANSI-shadow figlet style (thick block
 * letters with a shadow), the look used by modern terminal installers. Falls
 * back to a plain two-line wordmark when the terminal is narrow.
 */

// The wordmark is pre-rendered so we do not ship a figlet dependency. Each glyph
// is the standard ANSI-shadow shape (5 rows tall) for the letters we need.
const GLYPHS: Record<string, string[]> = {
  A: [' █████╗ ', '██╔══██╗', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝'],
  G: [' ██████╗ ', '██╔════╝ ', '██║  ███╗', '██║   ██║', '╚██████╔╝', ' ╚═════╝ '],
  E: ['███████╗', '██╔════╝', '█████╗  ', '██╔══╝  ', '███████╗', '╚══════╝'],
  N: ['███╗   ██╗', '████╗  ██║', '██╔██╗ ██║', '██║╚██╗██║', '██║ ╚████║', '╚═╝  ╚═══╝'],
  T: ['████████╗', '╚══██╔══╝', '   ██║   ', '   ██║   ', '   ██║   ', '   ╚═╝   '],
  S: ['███████╗', '██╔════╝', '███████╗', '╚════██║', '███████║', '╚══════╝'],
  K: ['██╗  ██╗', '██║ ██╔╝', '█████╔╝ ', '██╔═██╗ ', '██║  ██╗', '╚═╝  ╚═╝'],
  I: ['██╗', '██║', '██║', '██║', '██║', '╚═╝'],
  L: ['██╗     ', '██║     ', '██║     ', '██║     ', '███████╗', '╚══════╝'],
  ' ': ['  ', '  ', '  ', '  ', '  ', '  '],
};

export function ansiShadow(text: string): string[] {
  const rows = ['', '', '', '', '', ''];
  for (const ch of text.toUpperCase()) {
    const g = GLYPHS[ch] ?? GLYPHS[' '];
    for (let i = 0; i < rows.length; i++) rows[i] += g[i];
  }
  // Drop trailing spaces on each row.
  return rows.map((r) => r.replace(/\s+$/, ''));
}

/** Plain two-line fallback used when the terminal is too narrow. */
export function plainWordmark(): string[] {
  return ['A G E N T   S K I L L S'];
}
