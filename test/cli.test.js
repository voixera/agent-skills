/**
 * CLI configuration and non-TTY behaviour tests.
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

test('default invocation in a non-TTY prints help, does not hang', () => {
  const r = runCli([]);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /non-interactive shell/);
  assert.match(r.stdout, /npx agentskillsmd install/);
});

test('help lists the interactive default and commands', () => {
  const r = runCli(['help']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /Interactive installer \(TUI\)/);
});

test('validate exits 0 on a valid registry', () => {
  const r = runCli(['validate']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /PASS registry valid/);
});

test('list exits 0', () => {
  const r = runCli(['list', '-Category', 'svg']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /svg-craft/);
});

test('agents exits 0 and shows evidence levels', () => {
  const r = runCli(['agents']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /verified/);
  assert.match(r.stdout, /documented/);
});

test('unknown command falls through to non-TTY help (no crash)', () => {
  const r = runCli(['frobnicate']);
  assert.strictEqual(r.status, 0);
  assert.match(r.stdout, /non-interactive shell/);
});

test('non-interactive install then verify', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'agentskills-cli-'));
  try {
    const install = runCli([
      'install',
      '-Skills', 'svg-craft',
      '-Agents', 'codex',
      '-Scope', 'project',
      '-Path', tmp,
      '-Yes',
    ]);
    assert.strictEqual(install.status, 0, install.stdout + install.stderr);
    assert.ok(fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));

    const verify = runCli(['verify', '-Scope', 'project', '-Path', tmp]);
    assert.strictEqual(verify.status, 0, verify.stdout + verify.stderr);
    assert.match(verify.stdout, /PASS/);

    const uninstall = runCli(['uninstall', '-Skills', 'svg-craft', '-Scope', 'project', '-Path', tmp]);
    assert.strictEqual(uninstall.status, 0, uninstall.stdout + uninstall.stderr);
    assert.ok(!fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
