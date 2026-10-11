/**
 * SCREEN G - Completion.
 *
 * Accurate report: status, agents, skills, files, skips, warnings, and how to
 * verify / update / uninstall. No fabricated success: the status reflects the
 * engine's real exit code.
 */

import { select } from '@inquirer/prompts';
import type { Registry, UserSelection } from '../../types';
import { section, paint } from '../components/theme';
import { getAgent } from '../../core/registry';
import type { ProgressResult } from './progress';

export async function completeScreen(
  registry: Registry,
  selection: UserSelection,
  result: ProgressResult
): Promise<'menu' | 'quit'> {
  const ok = result.exitCode === 0;

  process.stdout.write(
    section(
      ok ? 'Installation complete' : 'Installation finished with errors',
      ok ? 'Your agents will pick up the skills in a new session.' : 'Some operations failed.'
    )
  );

  const agentNames = selection.agentIds.map((id) => getAgent(registry, id).name);
  process.stdout.write(`\n  ${paint('Summary', 'brand')}\n`);
  process.stdout.write(`    Status  : ${ok ? paint('SUCCESS', 'ok') : paint('FAILED', 'error')}\n`);
  process.stdout.write(`    Scope   : ${selection.scope}\n`);
  process.stdout.write(`    Agents  : ${agentNames.join(', ')}\n`);
  process.stdout.write(`    Skills  : ${selection.skillIds.length}\n`);
  process.stdout.write(
    `    Files   : ${paint(String(result.created), 'ok')} created, ` +
      `${paint(String(result.updated), 'warn')} updated, ${result.skipped} skipped\n`
  );
  if (result.warnings > 0) {
    process.stdout.write(`    Warnings: ${paint(String(result.warnings), 'warn')}\n`);
  }
  if (result.failed > 0) {
    process.stdout.write(`    Errors  : ${paint(String(result.failed), 'error')}\n`);
  }

  const failures = result.results.filter((r) => r.status === 'FAIL');
  if (failures.length > 0) {
    process.stdout.write(`\n  ${paint('Failures', 'error')}\n`);
    for (const f of failures) {
      process.stdout.write(`    ${f.name} - ${f.message}\n`);
    }
  }

  process.stdout.write(`\n  ${paint('Next steps', 'brand')}\n`);
  process.stdout.write(`    Re-run ${paint('npx agentskillsmd', 'brand')} to verify, update, or uninstall.\n`);

  process.stdout.write('\n');
  const next = await select({
    message: 'What next?',
    loop: false,
    choices: [
      { name: 'Back to main menu', value: 'menu' as const },
      { name: 'Exit', value: 'quit' as const },
    ],
  });

  return next;
}
