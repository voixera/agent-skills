/**
 * CLI entry point.
 *
 * The one and only path: launch the interactive TUI. There are no
 * subcommands to type. In a non-interactive environment (no TTY) we print a
 * short, honest notice telling the user to run it in a real terminal instead of
 * hanging.
 */

import { runApp } from '../tui/app';
import { banner, paint } from '../tui/components/theme';

export function isInteractive(): boolean {
  return Boolean(process.stdin.isTTY && process.stdout.isTTY);
}

function printNeedsTerminal(): void {
  process.stdout.write(banner());
  process.stdout.write(
    [
      '',
      `  ${paint('Agent Skills needs an interactive terminal.', 'warn')}`,
      '  This shell is not a TTY, so the installer menu cannot be shown.',
      '',
      '  Open Windows Terminal, PowerShell, CMD, or another terminal and run:',
      '',
      `    ${paint('npx agentskillsmd', 'brand')}`,
      '',
    ].join('\n')
  );
}

async function main(): Promise<number> {
  if (!isInteractive()) {
    printNeedsTerminal();
    return 0;
  }
  return runApp();
}

// Restore terminal state on interrupt. We never call process.exit() from the
// signal handler directly: that can truncate buffered stdout on some terminals.
// Instead we set the exit code and let the process end naturally, which flushes.
let interrupted = false;
process.on('SIGINT', () => {
  interrupted = true;
  process.stdout.write('\n');
  process.exitCode = 130;
});

main()
  .then((code) => {
    process.exitCode = interrupted ? 130 : code;
  })
  .catch((err) => {
    process.stderr.write(`\n  ${paint('Error:', 'error')} ${(err as Error).message}\n`);
    process.exitCode = 1;
  });
