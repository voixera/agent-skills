/**
 * Logos for the TUI banner.
 *
 * Two hand-rolled figlet-style wordmarks, pre-rendered so we do not ship a
 * figlet dependency:
 *   - ansiShadow: the classic thick block letters with a shadow (wide, 6 rows)
 *   - small:      a compact 3-row mark that fits an 80-column terminal
 *
 * The banner picks the widest one that fits the current terminal.
 */

// ---------------------------------------------------------------------------
// ANSI-shadow (wide, 6 rows)
// ---------------------------------------------------------------------------

const SHADOW: Record<string, string[]> = {
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
    const g = SHADOW[ch] ?? SHADOW[' '];
    for (let i = 0; i < rows.length; i++) rows[i] += g[i];
  }
  return rows.map((r) => r.replace(/\s+$/, ''));
}

// ---------------------------------------------------------------------------
// Small (compact, 3 rows) - fits an 80-column terminal for "AGENT SKILLS"
// ---------------------------------------------------------------------------

const SMALL: Record<string, string[]> = {
  A: ['  _   ', ' /_\\  ', '/_/ \\_\\'],
  G: ['  ___ ', ' / __|', '| (_ |'],
  E: [' ___ ', '| __|', '|___|'],
  N: [' _  _ ', '| \\| |', '|_|\\_|'],
  T: ['_____ ', '  |   ', '  |   '],
  S: [' ___ ', '/ __|', '\\__ \\'],
  K: [' _  _ ', '| |/ /', '|_|\\_\\'],
  I: ['___ ', ' |  ', '_|_ '],
  L: [' _   ', '| |  ', '|_|  '],
  ' ': [' ', ' ', ' '],
};

export function smallFont(text: string): string[] {
  const rows = ['', '', ''];
  for (const ch of text.toUpperCase()) {
    const g = SMALL[ch] ?? SMALL[' '];
    for (let i = 0; i < rows.length; i++) rows[i] += g[i];
  }
  return rows.map((r) => r.replace(/\s+$/, ''));
}

/**
 * Pick the widest wordmark that fits `columns`, else a one-line wordmark.
 * Returns the lines plus the font used.
 */
export function pickLogo(
  text: string,
  columns: number
): { lines: string[]; font: 'shadow' | 'small' | 'plain' } {
  const indent = 2;
  const fits = (lines: string[]) => Math.max(...lines.map((l) => l.length)) + indent <= columns;

  const big = ansiShadow(text);
  if (fits(big)) return { lines: big, font: 'shadow' };

  const mid = smallFont(text);
  if (fits(mid)) return { lines: mid, font: 'small' };

  return { lines: [text.toUpperCase().split('').join(' ')], font: 'plain' };
}
