/**
 * Manifest reading and writing (core).
 *
 * The engine writes the manifest; the TUI reads it to show what is installed
 * and to verify. Recorded paths are the only files uninstall will ever remove.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import * as crypto from 'node:crypto';
import type { Scope } from '../types';

export const MANIFEST_FILENAME = '.agent-skills-manifest.json';

export interface ManifestEntry {
  path: string;
  relativePath: string;
  skillId: string;
  agentId: string;
  skillVersion: string;
  scope: Scope;
  action: 'created' | 'modified' | 'managed-block';
  backup?: string | null;
  hash?: string | null;
  installedAt?: string;
  skillIds?: string[];
}

export interface Manifest {
  schemaVersion: number;
  toolVersion: string;
  scope: Scope;
  updated: string;
  files: ManifestEntry[];
}

export function homeDirectory(): string {
  return process.env.USERPROFILE || process.env.HOME || process.cwd();
}

export function manifestRoot(projectRoot: string, scope: Scope): string {
  return scope === 'user'
    ? path.join(homeDirectory(), '.agent-skills')
    : path.join(projectRoot, '.agent-skills');
}

export function manifestPath(projectRoot: string, scope: Scope): string {
  return path.join(manifestRoot(projectRoot, scope), MANIFEST_FILENAME);
}

export function readManifest(projectRoot: string, scope: Scope): Manifest {
  const file = manifestPath(projectRoot, scope);
  if (!fs.existsSync(file)) {
    return { schemaVersion: 1, toolVersion: '0.0.0', scope, updated: '', files: [] };
  }
  const raw = fs.readFileSync(file, 'utf8');
  try {
    const parsed = JSON.parse(raw) as Manifest;
    if (!Array.isArray(parsed.files)) {
      throw new Error("manifest is missing the 'files' property");
    }
    return parsed;
  } catch (err) {
    throw new Error(`Manifest at ${file} could not be read: ${(err as Error).message}`);
  }
}

export function installedSkillIds(manifest: Manifest): string[] {
  const ids = new Set<string>();
  for (const f of manifest.files) {
    if (f.skillIds?.length) for (const id of f.skillIds) ids.add(id);
    else if (f.skillId) for (const id of f.skillId.split(/,\s*/)) if (id) ids.add(id);
  }
  return [...ids];
}

// ---------------------------------------------------------------------------
// Writing helpers (used by the engine)
// ---------------------------------------------------------------------------

export function backupRoot(projectRoot: string, scope: Scope): string {
  return path.join(manifestRoot(projectRoot, scope), 'backups');
}

export function writeManifest(projectRoot: string, scope: Scope, manifest: Manifest): string {
  const file = manifestPath(projectRoot, scope);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  manifest.updated = new Date().toISOString();
  fs.writeFileSync(file, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  return file;
}

/** Normalised content hash (LF line endings) so CRLF/LF does not read as drift. */
export function contentHash(text: string): string {
  const normalised = text.replace(/\r\n/g, '\n');
  return crypto.createHash('sha256').update(normalised, 'utf8').digest('hex');
}

export function fileContentHash(file: string): string {
  return contentHash(fs.readFileSync(file, 'utf8'));
}

