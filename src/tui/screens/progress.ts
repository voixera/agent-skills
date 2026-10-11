/**
 * SCREEN F - Installation.
 *
 * Shows real progress. There is no artificial animation: each step reflects a
 * genuine operation, and a step is only marked done after it completes. The
 * heavy lifting (file writes, manifest) is performed by the PowerShell engine
 * in a single call; the surrounding steps are real too.
 */

import type { InstallResult, Registry, UserSelection } from '../../types';
import { paint } from '../components/theme';
import { executeInstall, verifyInstallation } from '../../core/installer';
import { resolveDependencies } from '../../core/resolver';

export interface ProgressResult {
  exitCode: number;
  results: InstallResult[];
  verify: InstallResult[];
  created: number;
  updated: number;
  skipped: number;
  failed: number;
  warnings: number;
}

export async function progressScreen(
  registry: Registry,
  selection: UserSelection,
  force: boolean
): Promise<ProgressResult> {
  process.stdout.write(`\n  ${paint('Installing...', 'brand')}\n\n`);

  const step = (label: string, ok: boolean, extra = '') => {
    const mark = ok ? paint('\u2713', 'ok') : paint('\u2717', 'error');
    process.stdout.write(`    ${mark} ${label}${extra ? `  ${paint(extra, 'dim')}` : ''}\n`);
  };

  // Step 1: registry is already validated at startup, but resolve for the record.
  let resolved: string[] = selection.skillIds;
  let addedDeps: string[] = [];
  try {
    const r = resolveDependencies(registry, selection.skillIds);
    resolved = r.resolved;
    addedDeps = r.addedDependencies;
    step('Resolving skill dependencies', true, `${resolved.length} skill(s)`);
  } catch (err) {
    step('Resolving skill dependencies', false, (err as Error).message);
    return { exitCode: 1, results: [], verify: [], created: 0, updated: 0, skipped: 0, failed: 1, warnings: 0 };
  }

  // Step 2: execute the engine (this performs real file writes + the manifest).
  let outcome;
  try {
    outcome = executeInstall({
      projectRoot: selection.projectRoot,
      scope: selection.scope,
      agentIds: selection.agentIds,
      skillIds: resolved,
      force,
    });
  } catch (err) {
    step('Running the installation engine', false, (err as Error).message);
    return { exitCode: 1, results: [], verify: [], created: 0, updated: 0, skipped: 0, failed: 1, warnings: 0 };
  }

  const created = outcome.results.filter((r) => r.status === 'PASS' && r.message === 'create').length;
  const updated = outcome.results.filter((r) => r.status === 'PASS' && r.message === 'overwrite').length;
  const skipped = outcome.results.filter((r) => r.status === 'SKIP').length;
  const failed = outcome.results.filter((r) => r.status === 'FAIL').length;
  const warnings = outcome.results.filter((r) => r.status === 'WARN').length;

  step('Writing skill files', outcome.exitCode === 0, `${created} new, ${updated} updated`);
  step('Writing installation manifest', outcome.exitCode === 0);

  // Step 3: verify against the manifest (real check).
  let verify: InstallResult[] = [];
  if (outcome.exitCode === 0) {
    try {
      const v = verifyInstallation(selection.projectRoot, selection.scope);
      verify = v.results;
      const bad = v.results.filter((r) => r.status === 'FAIL').length;
      step('Verifying installed files', bad === 0, bad === 0 ? 'all present' : `${bad} missing`);
    } catch (err) {
      step('Verifying installed files', false, (err as Error).message);
    }
  } else {
    step('Verifying installed files', false, 'skipped (install failed)');
  }

  process.stdout.write('\n');
  if (outcome.exitCode !== 0 && outcome.stderr) {
    process.stdout.write(`  ${paint('Engine output:', 'error')}\n`);
    process.stdout.write(
      outcome.stderr
        .split('\n')
        .map((l) => `    ${l}`)
        .join('\n') + '\n'
    );
  }

  return {
    exitCode: outcome.exitCode,
    results: outcome.results,
    verify,
    created,
    updated,
    skipped,
    failed,
    warnings,
  };
}
