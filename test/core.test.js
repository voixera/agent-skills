/**
 * Core tests (node:test). Run with: npm test
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { loadRegistry, loadAndValidateRegistry, validateRegistry } = require('../dist/core/registry');
const { resolveDependencies, expandPreset } = require('../dist/core/resolver');
const { buildPlan, summarizePlan, installPath } = require('../dist/core/planner');
const { readManifest, installedSkillIds, manifestPath } = require('../dist/core/manifest');

function tempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'agentskills-node-'));
}

test('registry loads and validates', () => {
  const reg = loadAndValidateRegistry();
  assert.ok(reg.skills.skills.length >= 50, 'expected at least 50 skills');
  assert.ok(reg.agents.agents.length >= 11, 'expected at least 11 agents');
  assert.ok(reg.presets.presets.length >= 7, 'expected at least 7 presets');
});

test('registry validation reports problems for a broken registry', () => {
  const reg = loadRegistry();
  const broken = JSON.parse(JSON.stringify(reg));
  broken.skills.skills[0].depends = ['does-not-exist'];
  const problems = validateRegistry(broken);
  assert.ok(problems.some((p) => p.includes('does-not-exist')));
});

test('resolver pulls in dependencies', () => {
  const reg = loadAndValidateRegistry();
  const r = resolveDependencies(reg, ['react-best-practices']);
  assert.ok(r.resolved.includes('react-best-practices'));
  assert.ok(r.resolved.includes('frontend-architecture'));
  assert.ok(r.addedDependencies.includes('frontend-architecture'));
});

test('resolver throws on unknown skill', () => {
  const reg = loadAndValidateRegistry();
  assert.throws(() => resolveDependencies(reg, ['nope']), /Unknown skill/);
});

test('preset expands to skill ids', () => {
  const reg = loadAndValidateRegistry();
  const skills = expandPreset(reg, 'minimal');
  assert.ok(skills.length >= 4);
});

test('planner produces create actions for a fresh project', () => {
  const reg = loadAndValidateRegistry();
  const tmp = tempDir();
  try {
    const plan = buildPlan({
      registry: reg,
      projectRoot: tmp,
      scope: 'project',
      agentIds: ['codex', 'claude-code'],
      skillIds: ['svg-craft'],
    });
    const s = summarizePlan(plan);
    assert.strictEqual(s.created, 2); // one per native agent
    assert.strictEqual(s.conflicts, 0);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('planner flags a conflict for an untracked file', () => {
  const reg = loadAndValidateRegistry();
  const tmp = tempDir();
  try {
    const dest = path.join(tmp, '.codex', 'skills', 'svg-craft');
    fs.mkdirSync(dest, { recursive: true });
    fs.writeFileSync(path.join(dest, 'SKILL.md'), 'user content');
    const plan = buildPlan({
      registry: reg,
      projectRoot: tmp,
      scope: 'project',
      agentIds: ['codex'],
      skillIds: ['svg-craft'],
    });
    assert.ok(plan.diagnostics.some((d) => d.category === 'conflict'));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('installPath resolves inside the project', () => {
  const reg = loadAndValidateRegistry();
  const agent = reg.agents.agents.find((a) => a.id === 'codex');
  const tmp = tempDir();
  try {
    const p = installPath(agent, 'svg-craft', 'project', tmp);
    assert.ok(p.startsWith(tmp));
    assert.ok(p.endsWith(path.join('svg-craft', 'SKILL.md')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('manifest is absent for a fresh project', () => {
  const tmp = tempDir();
  try {
    const m = readManifest(tmp, 'project');
    assert.strictEqual(m.files.length, 0);
    assert.strictEqual(installedSkillIds(m).length, 0);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
