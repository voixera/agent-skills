/**
 * TUI smoke test.
 *
 * We cannot allocate a real pseudo-terminal portably from a test, so we verify
 * the two things that matter deterministically:
 *   1. isInteractive() correctly reflects the TTY state.
 *   2. The TUI renders its banner and the interactive branch is chosen when a
 *      TTY is present (simulated by overriding isTTY), and we feed keystrokes
 *      through stdin to drive it to exit.
 *
 * If stdin cannot be driven, the test still asserts the banner output, which is
 * the requirement's first visible behaviour.
 */

const test = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const bin = path.join(root, 'bin', 'agentskillsmd.js');

test('banner and description render', () => {
  const r = spawnSync(process.execPath, [bin, 'help'], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1' },
  });
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /AGENT SKILLS/);
  assert.match(r.stdout, /Multi-agent skills manager/);
  assert.match(r.stdout, /v1\.1\.0/);
});

test('non-TTY is detected and does not launch the interactive TUI', () => {
  // spawnSync pipes stdin, so it is not a TTY.
  const r = spawnSync(process.execPath, [bin], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1' },
    timeout: 30000,
  });
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /non-interactive shell/);
  // It must NOT have blocked waiting for input.
});

test('interactive branch renders the welcome screen when a TTY is present', () => {
  // Force the interactive branch by overriding isTTY. The banner and the first
  // prompt are written before any key handling, so we assert on those and then
  // close stdin to let the process end without depending on signal timing.
  const driver = `
    Object.defineProperty(process.stdin, 'isTTY', { value: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true });
    if (!process.stdout.columns) {
      Object.defineProperty(process.stdout, 'columns', { value: 80 });
    }
    require(${JSON.stringify(path.join(root, 'dist', 'cli', 'entry.js'))});
    // Let the first screen render, then end input so inquirer rejects cleanly.
    setTimeout(() => { try { process.stdin.push(null); } catch (_) {} }, 1200);
    setTimeout(() => { process.exitCode = 0; process.exit(0); }, 2500);
  `;
  const r = spawnSync(process.execPath, ['-e', driver], {
    encoding: 'utf8',
    input: '\n',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1', FORCE_COLOR: '0' },
    timeout: 20000,
  });
  // The logo/banner must appear when the TUI runs.
  assert.match(r.stdout, /AGENT SKILLS/);
  // The first interactive question must appear.
  assert.match(r.stdout, /What would you like to do\?/);
});
