/**
 * TUI smoke tests.
 *
 * We cannot allocate a real pseudo-terminal portably, so these tests verify the
 * deterministic parts:
 *   1. The banner/description render (written synchronously).
 *   2. A non-TTY shell is detected and does not hang.
 *   3. With a faked TTY, the interactive branch is entered and the banner is
 *      produced (we assert on the banner, which precedes any key handling, so
 *      the test does not depend on prompt-render timing).
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const bin = path.join(root, 'bin', 'agentskillsmd.js');
const entry = path.join(root, 'dist', 'cli', 'entry.js');

test('banner and description render', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  const r = spawnSync(process.execPath, [bin], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1' },
  });
  assert.strictEqual(r.status, 0);
  // The block-font logo and the description line.
  assert.match(r.stdout, /Anti-slop rules for AI coding agents/);
  assert.match(r.stdout, /Multi-agent skills manager/);
  assert.ok(r.stdout.includes(`v${pkg.version}`), `expected banner to show v${pkg.version}`);
});

test('non-TTY is detected and does not launch the interactive TUI', () => {
  const r = spawnSync(process.execPath, [bin], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1' },
    timeout: 30000,
  });
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /needs an interactive terminal/i);
});

test('interactive branch enters the TUI when a TTY is present', () => {
  // Force the interactive branch. The banner is written synchronously before any
  // prompt, so asserting on it is stable regardless of prompt timing.
  const driver = `
    Object.defineProperty(process.stdin, 'isTTY', { value: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true });
    if (!process.stdout.columns) {
      Object.defineProperty(process.stdout, 'columns', { value: 80 });
    }
    require(${JSON.stringify(entry)});
    setTimeout(() => { try { process.stdin.push(null); } catch (_) {} }, 1500);
    setTimeout(() => { process.exit(0); }, 3000);
  `;
  const r = spawnSync(process.execPath, ['-e', driver], {
    encoding: 'utf8',
    input: '\n',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1', FORCE_COLOR: '0' },
    timeout: 20000,
  });
  // The TUI must not print the "needs a terminal" notice when a TTY is present.
  assert.doesNotMatch(r.stdout, /needs an interactive terminal/i);
  // The banner must appear (description line + stats).
  assert.match(r.stdout, /Anti-slop rules for AI coding agents/);
});
