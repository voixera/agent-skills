/**
 * Installation engine (core).
 *
 * The single source of install truth, in TypeScript. It applies a plan produced
 * by the planner: writes files, makes backups, records the manifest, and never
 * The single source of install truth, in TypeScript.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { InstallResult, Registry, Scope } from '../types';
import { buildPlan, summarizePlan, type PlanOptions } from './planner';
import {
  backupRoot,
  contentHash,
  fileContentHash,
  manifestRoot,
  readManifest,
  writeManifest,
  type Manifest,
  type ManifestEntry,
} from './manifest';
import { getSkill } from './registry';
import { readSkillContent } from './skill-content';
import { buildManagedBlock, mergeManagedBlock, MANAGED_BLOCK_MARKERS } from './adapters';

const TOOL_VERSION = '2.2.0';

function nowIso(): string {
  return new Date().toISOString();
}

function scopeRoot(projectRoot: string, scope: Scope): string {
  // Reuse the planner's logic via buildPlan's returned scopeRoot when available;
  // here we recompute for uninstall/verify.
  return scope === 'user'
    ? process.env.USERPROFILE || process.env.HOME || process.cwd()
    : path.resolve(projectRoot);
}

function isInside(candidate: string, root: string): boolean {
  const rel = path.relative(path.resolve(root), path.resolve(candidate));
  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}

function ensureDir(file: string): void {
  fs.mkdirSync(path.dirname(file), { recursive: true });
}

function writeFileSafe(file: string, content: string, root: string): void {
  if (!isInside(file, root)) {
    throw new Error(`Refusing to write outside the selected scope: ${file}`);
  }
  ensureDir(file);
  // LF endings, UTF-8, no BOM.
  fs.writeFileSync(file, content.replace(/\r\n/g, '\n'), 'utf8');
}

function backupFile(file: string, backups: string, root: string): string | null {
  if (!fs.existsSync(file)) return null;
  const rel = path.relative(root, file);
  const dest = path.join(backups, rel);
  ensureDir(dest);
  fs.copyFileSync(file, dest);
  return dest;
}

function removeEmptyDirs(startDir: string, root: string): void {
  let dir = path.resolve(startDir);
  const rootResolved = path.resolve(root);
  while (dir && dir !== rootResolved && isInside(dir, rootResolved) && fs.existsSync(dir)) {
    const children = fs.readdirSync(dir);
    if (children.length > 0) break;
    fs.rmdirSync(dir);
    dir = path.dirname(dir);
  }
}

// ---------------------------------------------------------------------------
// Apply
// ---------------------------------------------------------------------------

export interface ApplyOptions extends PlanOptions {
  force?: boolean;
  toolVersion?: string;
}

export interface ApplyOutcome {
  exitCode: number;
  results: InstallResult[];
  created: number;
  updated: number;
  skipped: number;
  failed: number;
}

export function applyPlan(registry: Registry, options: ApplyOptions): ApplyOutcome {
  const plan = buildPlan({
    registry,
    projectRoot: options.projectRoot,
    scope: options.scope,
    agentIds: options.agentIds,
    skillIds: options.skillIds,
    includeDependencies: options.includeDependencies,
  });

  const toolVersion = options.toolVersion ?? TOOL_VERSION;
  const root = plan.scopeRoot;
  const backups = backupRoot(options.projectRoot, options.scope);
  const manifest = readManifest(options.projectRoot, options.scope);
  const tracked = new Map(manifest.files.map((f) => [f.path, f]));

  const results: InstallResult[] = [];
  const touched = new Set(plan.actions.map((a) => a.destination));
  const newEntries: ManifestEntry[] = manifest.files.filter((f) => !touched.has(f.path));

  // Group aggregated skills per destination so we can build one block per file,
  // seeded with already-installed skills for that destination.
  const aggregated = new Map<string, { agentId: string; skillIds: string[] }>();
  for (const action of plan.actions) {
    if (action.kind !== 'managed-block') continue;
    const existing = aggregated.get(action.destination) ?? { agentId: action.agentId, skillIds: [] };
    for (const id of action.skillId.split(/,\s*/).filter(Boolean)) {
      if (!existing.skillIds.includes(id)) existing.skillIds.push(id);
    }
    aggregated.set(action.destination, existing);
  }
  // Seed aggregated with previously-installed skills at the same path.
  for (const [dest, entry] of aggregated) {
    const prior = tracked.get(dest);
    const priorIds = prior?.skillIds ?? (prior?.skillId ? prior.skillId.split(/,\s*/).filter(Boolean) : []);
    for (const id of priorIds) if (!entry.skillIds.includes(id)) entry.skillIds.unshift(id);
  }

  for (const action of plan.actions) {
    if (action.action === 'unchanged') {
      results.push({ status: 'SKIP', name: action.relativePath, message: '', reason: 'Already up to date', category: 'install' });
      const prior = tracked.get(action.destination);
      if (prior) newEntries.push(prior);
      continue;
    }

    const isConflict =
      action.action === 'overwrite' &&
      action.kind !== 'managed-block' &&
      !tracked.has(action.destination);

    if (isConflict && !options.force) {
      results.push({
        status: 'FAIL',
        name: action.relativePath,
        message: 'Existing untracked file; confirm overwrite to proceed (a backup is taken).',
        category: 'conflict',
      });
      continue;
    }

    try {
      let content: string;

      if (action.kind === 'managed-block') {
        const entry = aggregated.get(action.destination)!;
        const contents = entry.skillIds.map((id) => readSkillContent(getSkill(registry, id)));
        const block = buildManagedBlock(contents, toolVersion);
        const existing = fs.existsSync(action.destination) ? fs.readFileSync(action.destination, 'utf8') : null;
        content = mergeManagedBlock(existing, block);
      } else {
        // Re-render to fetch exact content (the planner keeps actions light).
        const rendered = renderActionContent(registry, action.skillId, action.agentId);
        content = rendered;
      }

      let backupPath: string | null = null;
      if (action.action === 'overwrite') {
        backupPath = backupFile(action.destination, backups, root);
      }

      writeFileSafe(action.destination, content, root);

      results.push({ status: 'PASS', name: action.relativePath, message: action.action, category: 'install' });

      const manifestAction =
        action.action === 'create'
          ? 'created'
          : action.kind === 'managed-block'
          ? 'managed-block'
          : 'modified';

      const entry: ManifestEntry = {
        path: action.destination,
        relativePath: action.relativePath,
        skillId: action.skillId,
        agentId: action.agentId,
        skillVersion: action.skillVersion,
        scope: options.scope,
        action: manifestAction,
        backup: backupPath,
        hash: contentHash(content),
        installedAt: nowIso(),
      };
      if (action.kind === 'managed-block') {
        entry.skillIds = aggregated.get(action.destination)!.skillIds;
      }
      newEntries.push(entry);
    } catch (err) {
      results.push({ status: 'FAIL', name: action.relativePath, message: (err as Error).message, category: 'install' });
    }
  }

  writeManifest(options.projectRoot, options.scope, {
    schemaVersion: 1,
    toolVersion,
    scope: options.scope,
    updated: nowIso(),
    files: newEntries,
  });

  const summary = summarizePlan(plan);
  void summary;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  const created = results.filter((r) => r.status === 'PASS' && r.message === 'create').length;
  const updated = results.filter((r) => r.status === 'PASS' && r.message === 'overwrite').length;
  const skipped = results.filter((r) => r.status === 'SKIP').length;
  return { exitCode: failed > 0 ? 1 : 0, results, created, updated, skipped, failed };
}

/** Render a single skill for one agent (used during apply). */
function renderActionContent(registry: Registry, skillId: string, agentId: string): string {
  // Imported lazily to avoid a cycle with adapters -> skill-content.
  const { renderForAgent } = require('./adapters') as typeof import('./adapters');
  const agent = registry.agents.agents.find((a) => a.id === agentId)!;
  const skill = getSkill(registry, skillId);
  return renderForAgent(readSkillContent(skill), agent);
}

// ---------------------------------------------------------------------------
// Verify
// ---------------------------------------------------------------------------

export function verify(projectRoot: string, scope: Scope): InstallResult[] {
  const manifest = readManifest(projectRoot, scope);
  if (manifest.files.length === 0) {
    return [{ status: 'SKIP', name: `manifest (${scope})`, message: '', reason: 'Nothing installed for this scope', category: 'verify' }];
  }
  const results: InstallResult[] = [];
  for (const f of manifest.files) {
    if (!fs.existsSync(f.path)) {
      results.push({ status: 'FAIL', name: f.relativePath, message: 'File recorded in manifest is missing', category: 'verify' });
      continue;
    }
    if (f.hash) {
      const current = fileContentHash(f.path);
      if (current !== f.hash) {
        results.push({ status: 'WARN', name: f.relativePath, message: 'File has been modified since install', category: 'verify' });
        continue;
      }
    }
    results.push({ status: 'PASS', name: f.relativePath, message: 'present', category: 'verify' });
  }
  return results;
}

// ---------------------------------------------------------------------------
// Uninstall
// ---------------------------------------------------------------------------

export interface UninstallOptions {
  projectRoot: string;
  scope: Scope;
  skillIds?: string[];
  agentIds?: string[];
  all?: boolean;
}

export function uninstallSkills(registry: Registry, options: UninstallOptions): InstallResult[] {
  const { projectRoot, scope } = options;
  const removeSkill = new Set(options.skillIds ?? []);
  const removeAgent = new Set(options.agentIds ?? []);
  const all = options.all ?? false;

  if (!all && removeSkill.size === 0 && removeAgent.size === 0) {
    throw new Error('Uninstall requires -All or at least one skill/agent selection.');
  }

  const manifest = readManifest(projectRoot, scope);
  const root = scopeRoot(projectRoot, scope);
  const results: InstallResult[] = [];
  const keep: ManifestEntry[] = [];

  for (const e of manifest.files) {
    const entrySkillIds = e.skillIds?.length ? e.skillIds : e.skillId ? e.skillId.split(/,\s*/).filter(Boolean) : [];
    const agentMatches = removeAgent.size === 0 || removeAgent.has(e.agentId);

    let remainingSkillIds: string[];
    if (all) {
      remainingSkillIds = [];
    } else if (e.action === 'managed-block') {
      remainingSkillIds = entrySkillIds.filter((id) => !removeSkill.has(id));
      if (removeSkill.size > 0 && entrySkillIds.length > 0 && remainingSkillIds.length === entrySkillIds.length) {
        keep.push(e); // nothing in this block was selected
        continue;
      }
    } else {
      const selected = entrySkillIds.some((id) => removeSkill.has(id));
      if (!selected || !agentMatches) {
        keep.push(e);
        continue;
      }
      remainingSkillIds = [];
    }

    // Managed block with survivors: regenerate in place.
    if (e.action === 'managed-block' && remainingSkillIds.length > 0) {
      try {
        const contents = remainingSkillIds.map((id) => readSkillContent(getSkill(registry, id)));
        const block = buildManagedBlock(contents, TOOL_VERSION);
        const existing = fs.existsSync(e.path) ? fs.readFileSync(e.path, 'utf8') : null;
        const merged = mergeManagedBlock(existing, block);
        writeFileSafe(e.path, merged, root);
        results.push({ status: 'PASS', name: e.relativePath, message: `block updated (kept: ${remainingSkillIds.join(', ')})`, category: 'uninstall' });
        keep.push({ ...e, skillId: remainingSkillIds.join(', '), skillIds: remainingSkillIds, hash: contentHash(merged) });
      } catch (err) {
        results.push({ status: 'FAIL', name: e.relativePath, message: (err as Error).message, category: 'uninstall' });
        keep.push(e);
      }
      continue;
    }

    // Whole-file removal.
    try {
      if (!isInside(e.path, root)) {
        throw new Error(`Refusing to delete outside the selected scope: ${e.path}`);
      }
      if (fs.existsSync(e.path)) {
        fs.rmSync(e.path, { force: true });
        results.push({ status: 'PASS', name: e.relativePath, message: 'removed', category: 'uninstall' });
        removeEmptyDirs(path.dirname(e.path), root);
      } else {
        results.push({ status: 'SKIP', name: e.relativePath, message: '', reason: 'Already absent', category: 'uninstall' });
      }
    } catch (err) {
      results.push({ status: 'FAIL', name: e.relativePath, message: (err as Error).message, category: 'uninstall' });
    }
  }

  writeManifest(projectRoot, scope, {
    schemaVersion: 1,
    toolVersion: TOOL_VERSION,
    scope,
    updated: nowIso(),
    files: keep,
  });

  return results;
}

export { MANAGED_BLOCK_MARKERS, manifestRoot };
