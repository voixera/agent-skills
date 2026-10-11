/**
 * CLI configuration and non-TTY behaviour tests.
 *
 * The CLI is TUI-only: no subcommands. These tests verify that package wiring is
 * correct, that a non-TTY shell gets a clear message (and does not hang), and
 * that the underlying engine (used by the TUI) installs, verifies, and
 * uninstalls correctly.
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const bin = path.join(root, 'bin', 'agentskillsmd.js');

function runCli(args, env = {}) {
  return spawnSync(process.execPath, [bin, ...args], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1', ...env },
    timeout: 120000,
  });
}

test('package.json maps the bin to the executable', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.name, 'agentskillsmd');
  assert.strictEqual(pkg.bin.agentskillsmd, 'bin/agentskillsmd.js');
  assert.ok(pkg.files.includes('dist/'), 'dist must be published');
  assert.ok(pkg.files.includes('installer/'), 'installer engine must be published');
});

test('default invocation in a non-TTY prints a notice, does not hang', () => {
  const r = runCli([]);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /needs an interactive terminal/i);
  assert.match(r.stdout, /npx agentskillsmd/);
});

test('no subcommands: arguments never bypass the TUI', () => {
  // Any argument still routes to the TUI / non-TTY notice; there is no command
  // dispatch. We assert we do not, for example, run an "install" command.
  const r = runCli(['list', '-Category', 'svg']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /needs an interactive terminal/i);
});

test('engine install -> verify -> uninstall (as the TUI uses it)', () => {
  const { executeInstall, verifyInstallation, uninstall } = require('../dist/core/installer');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'agentskills-engine-'));
  try {
    const install = executeInstall({
      projectRoot: tmp,
      scope: 'project',
      agentIds: ['codex'],
      skillIds: ['svg-craft'],
    });
    assert.strictEqual(install.exitCode, 0, install.stdout + install.stderr);
    assert.ok(fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));

    const verify = verifyInstallation(tmp, 'project');
    assert.strictEqual(verify.exitCode, 0, 'verify should pass');
    assert.ok(verify.results.some((r) => r.status === 'PASS'));

    const rm = uninstall(tmp, 'project', ['svg-craft'], []);
    assert.strictEqual(rm.exitCode, 0, rm.stdout + rm.stderr);
    assert.ok(!fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
