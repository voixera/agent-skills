/**
 * CLI configuration and non-TTY behaviour tests.
 *
 * The CLI is TUI-only: no subcommands. These tests verify package wiring and
 * that a non-TTY shell gets a clear message (and does not hang).
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const bin = path.join(root, 'bin', 'agentskillsmd.js');

function runCli(args, env = {}) {
  return spawnSync(process.execPath, [bin, ...args], {
    encoding: 'utf8',
    env: { ...process.env, AGENT_SKILLS_NO_COLOR: '1', ...env },
    timeout: 60000,
  });
}

test('package.json maps the bin to the executable', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.name, 'agentskillsmd');
  assert.strictEqual(pkg.bin.agentskillsmd, 'bin/agentskillsmd.js');
  assert.ok(pkg.files.includes('dist/'), 'dist must be published');
  assert.ok(!pkg.files.includes('installer/'), 'PowerShell installer must not be published');
});

test('default invocation in a non-TTY prints a notice, does not hang', () => {
  const r = runCli([]);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /needs an interactive terminal/i);
  assert.match(r.stdout, /npx agentskillsmd/);
});

test('no subcommands: arguments never bypass the TUI', () => {
  const r = runCli(['list', '-Category', 'svg']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /needs an interactive terminal/i);
});

test('the package no longer ships any PowerShell', () => {
  assert.ok(!fs.existsSync(path.join(root, 'installer')), 'installer/ should be deleted');
  assert.ok(!fs.existsSync(path.join(root, 'src', 'AgentSkills')), 'src/AgentSkills should be deleted');
  assert.ok(!fs.existsSync(path.join(root, 'tests')), 'PS tests/ should be deleted');
});
