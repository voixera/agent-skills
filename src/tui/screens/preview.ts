/**
 * SCREEN E - Installation preview.
 *
 * Shows exactly what will happen using the in-process dry-run planner:
 * selected agents, skills, scope, files to create/update, conflicts, and
 * dependencies. Nothing is written until the user confirms.
 */

import { select, confirm } from '@inquirer/prompts';
import type { Registry, UserSelection } from '../../types';
import { section, paint } from '../components/theme';
import { buildPlan, summarizePlan } from '../../core/planner';
import { getAgent } from '../../core/registry';

export interface PreviewResult {
  selection: UserSelection;
  force: boolean;
}

export async function previewScreen(
  registry: Registry,
  selection: UserSelection
): Promise<PreviewResult | 'back'> {
  process.stdout.write(section('Installation preview', 'Review before writing anything.'));

  const plan = buildPlan({
    registry,
    projectRoot: selection.projectRoot,
    scope: selection.scope,
    agentIds: selection.agentIds,
    skillIds: selection.skillIds,
  });
  const summary = summarizePlan(plan);

  const agentNames = selection.agentIds.map((id) => getAgent(registry, id).name);

  process.stdout.write(`\n  ${paint('Configuration', 'brand')}\n`);
  process.stdout.write(`    Scope        : ${selection.scope}  (${plan.scopeRoot})\n`);
  process.stdout.write(`    Agents       : ${agentNames.join(', ')}\n`);
  process.stdout.write(`    Skills       : ${plan.resolved.length}\n`);
  if (plan.addedDependencies.length > 0) {
    process.stdout.write(
      `    + dependencies: ${paint(plan.addedDependencies.join(', '), 'warn')}\n`
    );
  }
  process.stdout.write(
    `    Files        : ${paint(String(summary.created), 'ok')} new, ` +
      `${paint(String(summary.updated), 'warn')} update, ${summary.unchanged} unchanged\n`
  );

  if (plan.actions.length > 0) {
    process.stdout.write(`\n  ${paint('Files', 'brand')}\n`);
    for (const a of plan.actions) {
      const tag =
        a.action === 'create'
          ? paint('[new   ]', 'ok')
          : a.action === 'overwrite'
          ? paint('[update]', 'warn')
          : paint('[same  ]', 'dim');
      process.stdout.write(`    ${tag} ${a.relativePath}\n`);
    }
  }

  const conflicts = plan.diagnostics.filter((d) => d.category === 'conflict');
  const warnings = plan.diagnostics.filter((d) => d.status === 'WARN');
  if (conflicts.length > 0) {
    process.stdout.write(`\n  ${paint('Conflicts require attention', 'error')}\n`);
    for (const c of conflicts) process.stdout.write(`    ${paint(c.name, 'error')} - ${c.message}\n`);
  }
  if (warnings.length > 0) {
    process.stdout.write(`\n  ${paint('Notes', 'warn')}\n`);
    for (const w of warnings) process.stdout.write(`    ${w.name} - ${w.message}\n`);
  }

  process.stdout.write('\n');

  const action = await select({
    message: 'Proceed?',
    loop: false,
    choices: [
      { name: 'Install now', value: 'install' as const },
      ...(conflicts.length > 0
        ? [{ name: 'Install and overwrite conflicting files (a backup is taken)', value: 'force' as const }]
        : []),
      { name: 'Back', value: 'back' as const },
    ],
  });

  if (action === 'back') return 'back';

  const force = action === 'force';
  if (force) {
    const ok = await confirm({
      message: paint('Overwrite untracked files that conflict? This replaces them (backups are kept).', 'warn'),
      default: false,
    });
    if (!ok) return 'back';
  }

  return { selection, force };
}
