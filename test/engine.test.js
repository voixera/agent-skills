/**
 * Engine tests (node:test): install, verify, uninstall, safety.
 * All work happens in isolated temp directories.
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { loadAndValidateRegistry } = require('../dist/core/registry');
const { executeInstall, verifyInstallation, uninstall } = require('../dist/core/installer');
const { buildPlan, summarizePlan } = require('../dist/core/planner');
const { readManifest } = require('../dist/core/manifest');

function tempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'agentskills-engine-'));
}

const reg = loadAndValidateRegistry();

test('install creates native files for two agents', () => {
  const tmp = tempDir();
  try {
    const r = executeInstall({
      registry: reg,
      projectRoot: tmp,
      scope: 'project',
      agentIds: ['codex', 'claude-code'],
      skillIds: ['svg-craft'],
    });
    assert.strictEqual(r.exitCode, 0);
    assert.strictEqual(r.created, 2);
    assert.ok(fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));
    assert.ok(fs.existsSync(path.join(tmp, '.claude', 'skills', 'svg-craft', 'SKILL.md')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('install writes a manifest', () => {
  const tmp = tempDir();
  try {
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    const m = readManifest(tmp, 'project');
    assert.strictEqual(m.files.length, 1);
    assert.strictEqual(m.files[0].skillId, 'svg-craft');
    assert.strictEqual(m.files[0].agentId, 'codex');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('install is idempotent', () => {
  const tmp = tempDir();
  try {
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    const r = executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    assert.strictEqual(r.skipped, 1);
    assert.strictEqual(r.failed, 0);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('verify passes after a clean install', () => {
  const tmp = tempDir();
  try {
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    const v = verifyInstallation(tmp, 'project');
    assert.strictEqual(v.exitCode, 0);
    assert.ok(v.results.every((r) => r.status === 'PASS'));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('conflict: untracked file is not overwritten without force', () => {
  const tmp = tempDir();
  try {
    const dest = path.join(tmp, '.codex', 'skills', 'svg-craft');
    fs.mkdirSync(dest, { recursive: true });
    fs.writeFileSync(path.join(dest, 'SKILL.md'), 'user owned');
    const r = executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    assert.strictEqual(r.exitCode, 1);
    assert.ok(r.results.some((x) => x.category === 'conflict'));
    assert.strictEqual(fs.readFileSync(path.join(dest, 'SKILL.md'), 'utf8'), 'user owned');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('force overwrites and takes a backup', () => {
  const tmp = tempDir();
  try {
    const dest = path.join(tmp, '.codex', 'skills', 'svg-craft');
    fs.mkdirSync(dest, { recursive: true });
    fs.writeFileSync(path.join(dest, 'SKILL.md'), 'user owned');
    const r = executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'], force: true });
    assert.strictEqual(r.exitCode, 0);
    const backup = path.join(tmp, '.agent-skills', 'backups', '.codex', 'skills', 'svg-craft', 'SKILL.md');
    assert.ok(fs.existsSync(backup));
    assert.strictEqual(fs.readFileSync(backup, 'utf8'), 'user owned');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('aggregated block merges and preserves user content', () => {
  const tmp = tempDir();
  try {
    fs.writeFileSync(path.join(tmp, 'AGENTS.md'), '# Project\n\nUser instructions.');
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['universal'], skillIds: ['svg-craft'] });
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['universal'], skillIds: ['icon-design'] });
    const c = fs.readFileSync(path.join(tmp, 'AGENTS.md'), 'utf8');
    assert.match(c, /User instructions/);
    assert.match(c, /SVG Craft/);
    assert.match(c, /Icon Design/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('uninstall removes only managed files and keeps user files', () => {
  const tmp = tempDir();
  try {
    fs.mkdirSync(path.join(tmp, '.codex', 'skills'), { recursive: true });
    fs.writeFileSync(path.join(tmp, '.codex', 'skills', 'user-note.md'), 'keep me');
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    uninstall(reg, tmp, 'project', ['svg-craft'], []);
    assert.ok(!fs.existsSync(path.join(tmp, '.codex', 'skills', 'svg-craft', 'SKILL.md')));
    assert.ok(fs.existsSync(path.join(tmp, '.codex', 'skills', 'user-note.md')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('uninstall one skill keeps another in a shared block', () => {
  const tmp = tempDir();
  try {
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['universal'], skillIds: ['svg-craft'] });
    executeInstall({ registry: reg, projectRoot: tmp, scope: 'project', agentIds: ['universal'], skillIds: ['icon-design'] });
    uninstall(reg, tmp, 'project', ['svg-craft'], []);
    const c = fs.readFileSync(path.join(tmp, 'AGENTS.md'), 'utf8');
    assert.doesNotMatch(c, /## SVG Craft/);
    assert.match(c, /Icon Design/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('planner resolves dependencies', () => {
  const plan = buildPlan({
    registry: reg,
    projectRoot: process.cwd(),
    scope: 'project',
    agentIds: ['codex'],
    skillIds: ['react-best-practices'],
  });
  assert.ok(plan.resolved.includes('frontend-architecture'));
  assert.ok(plan.addedDependencies.includes('frontend-architecture'));
});

test('path with spaces installs correctly', () => {
  const base = tempDir();
  const spaced = path.join(base, 'a folder with spaces');
  fs.mkdirSync(spaced, { recursive: true });
  try {
    const r = executeInstall({ registry: reg, projectRoot: spaced, scope: 'project', agentIds: ['codex'], skillIds: ['svg-craft'] });
    assert.strictEqual(r.exitCode, 0);
    assert.ok(fs.existsSync(path.join(spaced, '.codex', 'skills', 'svg-craft', 'SKILL.md')));
  } finally {
    fs.rmSync(base, { recursive: true, force: true });
  }
});
