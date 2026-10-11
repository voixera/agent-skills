/**
 * Registry loading and validation (core).
 *
 * The TUI talks to this module, never to the filesystem. It resolves the
 * repository root, reads the three registries, and performs structural
 * validation so the TUI can present honest compatibility information.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type {
  AgentsRegistry,
  PresetsRegistry,
  Registry,
  SkillEntry,
  SkillsRegistry,
} from '../types';

/**
 * Resolve the package root.
 *
 * Works from source (src/core/registry.ts -> repo root) and from the compiled
 * output (dist/core/registry.js -> repo root). Both are three levels below the
 * package root. AGENT_SKILLS_ROOT overrides for tests.
 */
export function resolvePackageRoot(): string {
  if (process.env.AGENT_SKILLS_ROOT && fs.existsSync(process.env.AGENT_SKILLS_ROOT)) {
    return path.resolve(process.env.AGENT_SKILLS_ROOT);
  }
  let dir = __dirname;
  for (let i = 0; i < 5; i++) {
    if (fs.existsSync(path.join(dir, 'registry', 'skills.json'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error(
    'Could not locate the Agent Skills package root (expected a registry/ folder). ' +
      'Set AGENT_SKILLS_ROOT to override.'
  );
}

function readJson<T>(file: string): T {
  if (!fs.existsSync(file)) {
    throw new Error(`Required registry file is missing: ${file}`);
  }
  const raw = fs.readFileSync(file, 'utf8');
  try {
    return JSON.parse(raw) as T;
  } catch (err) {
    throw new Error(`Failed to parse ${file}: ${(err as Error).message}`);
  }
}

export interface LoadOptions {
  root?: string;
}

export function loadRegistry(options: LoadOptions = {}): Registry {
  const root = options.root ?? resolvePackageRoot();
  const regDir = path.join(root, 'registry');
  return {
    agents: readJson<AgentsRegistry>(path.join(regDir, 'agents.json')),
    skills: readJson<SkillsRegistry>(path.join(regDir, 'skills.json')),
    presets: readJson<PresetsRegistry>(path.join(regDir, 'presets.json')),
  };
}

export class RegistryError extends Error {
  public readonly problems: string[];
  constructor(problems: string[]) {
    super(`Registry validation failed with ${problems.length} problem(s).`);
    this.name = 'RegistryError';
    this.problems = problems;
  }
}

/**
 * Structural validation. Returns a list of human-readable problems (empty means
 * valid). Cross-references (agent ids, preset refs, dependency cycles) are
 * checked here so the TUI can fail early with a clear message.
 */
export function validateRegistry(reg: Registry): string[] {
  const problems: string[] = [];

  if (!Array.isArray(reg.skills.skills) || reg.skills.skills.length === 0) {
    problems.push('registry/skills.json contains no skills.');
  }
  if (!Array.isArray(reg.agents.agents) || reg.agents.agents.length === 0) {
    problems.push('registry/agents.json contains no agents.');
  }
  if (!Array.isArray(reg.presets.presets) || reg.presets.presets.length === 0) {
    problems.push('registry/presets.json contains no presets.');
  }

  const skillIds = new Set<string>();
  for (const s of reg.skills.skills ?? []) {
    if (skillIds.has(s.id)) problems.push(`Duplicate skill id: ${s.id}`);
    skillIds.add(s.id);
    if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(s.id)) {
      problems.push(`Skill id is not kebab-case: ${s.id}`);
    }
  }

  const agentIds = new Set<string>();
  for (const a of reg.agents.agents ?? []) {
    if (agentIds.has(a.id)) problems.push(`Duplicate agent id: ${a.id}`);
    agentIds.add(a.id);
  }

  for (const s of reg.skills.skills ?? []) {
    for (const dep of s.depends ?? []) {
      if (!skillIds.has(dep)) problems.push(`Skill '${s.id}' depends on unknown skill '${dep}'.`);
    }
    for (const a of s.agents ?? []) {
      if (!agentIds.has(a)) problems.push(`Skill '${s.id}' references unknown agent '${a}'.`);
    }
  }

  for (const p of reg.presets.presets ?? []) {
    for (const ref of p.skills ?? []) {
      if (!skillIds.has(ref)) problems.push(`Preset '${p.id}' references unknown skill '${ref}'.`);
    }
  }

  // Cycle detection across the dependency graph.
  const WHITE = 0;
  const GRAY = 1;
  const BLACK = 2;
  const color = new Map<string, number>();
  const byId = new Map<string, SkillEntry>();
  for (const s of reg.skills.skills ?? []) byId.set(s.id, s);

  const visit = (id: string, stack: string[]): void => {
    color.set(id, GRAY);
    for (const dep of byId.get(id)?.depends ?? []) {
      const c = color.get(dep) ?? WHITE;
      if (c === GRAY) {
        problems.push(`Dependency cycle: ${[...stack, id, dep].join(' -> ')}`);
      } else if (c === WHITE) {
        visit(dep, [...stack, id]);
      }
    }
    color.set(id, BLACK);
  };
  for (const s of reg.skills.skills ?? []) {
    if ((color.get(s.id) ?? WHITE) === WHITE) visit(s.id, []);
  }

  return problems;
}

export function loadAndValidateRegistry(options: LoadOptions = {}): Registry {
  const reg = loadRegistry(options);
  const problems = validateRegistry(reg);
  if (problems.length > 0) {
    throw new RegistryError(problems);
  }
  return reg;
}

export function getSkill(reg: Registry, id: string): SkillEntry {
  const found = reg.skills.skills.find((s) => s.id === id);
  if (!found) throw new Error(`Unknown skill id: '${id}'.`);
  return found;
}

export function getAgent(reg: Registry, id: string) {
  const found = reg.agents.agents.find((a) => a.id === id);
  if (!found) throw new Error(`Unknown agent id: '${id}'.`);
  return found;
}

export function getPreset(reg: Registry, id: string) {
  const found = reg.presets.presets.find((p) => p.id === id);
  if (!found) throw new Error(`Unknown preset id: '${id}'.`);
  return found;
}

export function skillsByCategory(reg: Registry): Map<string, SkillEntry[]> {
  const map = new Map<string, SkillEntry[]>();
  for (const s of reg.skills.skills) {
    const list = map.get(s.category) ?? [];
    list.push(s);
    map.set(s.category, list);
  }
  for (const list of map.values()) list.sort((a, b) => a.id.localeCompare(b.id));
  return map;
}

export function searchSkills(reg: Registry, term: string): SkillEntry[] {
  const needle = term.trim().toLowerCase();
  if (!needle) return [];
  return reg.skills.skills.filter(
    (s) =>
      s.id.toLowerCase().includes(needle) ||
      s.name.toLowerCase().includes(needle) ||
      s.description.toLowerCase().includes(needle)
  );
}
