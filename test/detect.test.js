/**
 * Detector tests (node:test).
 */

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { loadAndValidateRegistry } = require('../dist/core/registry');
const { detectAgent, detectAll, agentInstallUrl } = require('../dist/core/detect');

const reg = loadAndValidateRegistry();

test('every agent has an install URL', () => {
  for (const a of reg.agents.agents) {
    const url = agentInstallUrl(a);
    assert.ok(url && /^https?:\/\//.test(url), `agent '${a.id}' should have an http(s) install URL`);
  }
});

test('detectAgent reports not installed for a fresh project', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'detect-'));
  try {
    // A project-scope marker that does not exist must report not installed,
    // unless the agent also has a user-level marker present on this machine.
    const cursor = reg.agents.agents.find((a) => a.id === 'cursor');
    const det = detectAgent(cursor, tmp);
    assert.strictEqual(det.installed, false, 'cursor should not be detected in an empty temp dir');
    assert.deepStrictEqual(det.matched, []);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('detectAgent sees a project marker when present', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'detect-'));
  try {
    // github-copilot detects a '.github' project marker.
    fs.mkdirSync(path.join(tmp, '.github'), { recursive: true });
    const copilot = reg.agents.agents.find((a) => a.id === 'github-copilot');
    const det = detectAgent(copilot, tmp);
    assert.strictEqual(det.installed, true);
    assert.ok(det.matched.includes('.github'));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('detectAll returns one entry per agent', () => {
  const all = detectAll(reg, process.cwd());
  assert.strictEqual(all.length, reg.agents.agents.length);
});
