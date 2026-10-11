/**
 * SCREEN F - Installation.
 *
 * Shows real progress. There is no artificial animation: each step reflects a
 * genuine operation, and a step is only marked done after it completes. The
 * engine runs in-process (TypeScript).
 */

import type { InstallResult, Registry, UserSelection } from '../../types';
import { paint } from '../components/theme';
import { executeInstall } from '../../core/installer';
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

  // Step 1: resolve dependencies.
  let resolved: string[] = selection.skillIds;
  try {
    const r = resolveDependencies(registry, selection.skillIds);
    resolved = r.resolved;
    step('Resolving skill dependencies', true, `${resolved.length} skill(s)`);
  } catch (err) {
    step('Resolving skill dependencies', false, (err as Error).message);
    return { exitCode: 1, results: [], verify: [], created: 0, updated: 0, skipped: 0, failed: 1, warnings: 0 };
  }

  // Step 2: apply the plan (real file writes + manifest).
  let outcome;
  try {
    outcome = executeInstall({
      registry,
      projectRoot: selection.projectRoot,
      scope: selection.scope,
      agentIds: selection.agentIds,
      skillIds: resolved,
      force,
    });
  } catch (err) {
    step('Applying the installation plan', false, (err as Error).message);
    return { exitCode: 1, results: [], verify: [], created: 0, updated: 0, skipped: 0, failed: 1, warnings: 0 };
  }

  step('Writing skill files', outcome.failed === 0, `${outcome.created} new, ${outcome.updated} updated`);
  step('Writing installation manifest', outcome.failed === 0);

  process.stdout.write('\n');

  return {
    exitCode: outcome.exitCode,
    results: outcome.results,
    verify: [],
    created: outcome.created,
    updated: outcome.updated,
    skipped: outcome.skipped,
    failed: outcome.failed,
    warnings: outcome.results.filter((r) => r.status === 'WARN').length,
  };
}

