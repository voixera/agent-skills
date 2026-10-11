/**
 * Version, from a single source of truth.
 *
 * The only place the version is written by hand is package.json. Everything else
 * (the banner, the manifest's toolVersion, the managed-block header) reads it
 * from here, so a version bump never has to be repeated in the source.
 *
 * Resolution order:
 *   1. package.json next to the running file (normal install / build).
 *   2. package.json at the package root (resolved by walking up).
 *   3. '0.0.0' as a last resort (never throws).
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

let cached: string | null = null;

function readPackageVersion(): string {
  // Candidates: dist/core/ -> ../../package.json ; src/core -> ../../package.json.
  const candidates = [
    path.join(__dirname, '..', '..', 'package.json'),
    path.join(__dirname, '..', '..', '..', 'package.json'),
  ];
  for (const file of candidates) {
    try {
      const pkg = JSON.parse(fs.readFileSync(file, 'utf8')) as { name?: string; version?: string };
      if (pkg.name === 'agentskillsmd' && typeof pkg.version === 'string') {
        return pkg.version;
      }
    } catch {
      // try next
    }
  }
  return '0.0.0';
}

export function toolVersion(): string {
  if (cached === null) cached = readPackageVersion();
  return cached;
}
