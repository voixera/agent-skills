/**
 * SCREEN C - AI agent selection.
 *
 * Multi-select of supported agents, filtered by scope, showing:
 *   - installed / not-installed state (from the detector),
 *   - support level and evidence.
 *
 * After the checkbox, if any selected agent is not installed, the user is
 * offered a link to that agent's installer page.
 */

import { confirm } from '@inquirer/prompts';
import type { Registry, Scope } from '../../types';
import { section, paint } from '../components/theme';
import { plainCheckbox } from '../components/prompts';
import { detectAgent, openUrl, agentInstallUrl } from '../../core/detect';

export interface AgentChoice {
  agentIds: string[];
}

export async function agentsScreen(
  registry: Registry,
  scope: Scope
): Promise<AgentChoice | 'back'> {
  process.stdout.write(
    section(
      'Select AI agents',
      `Agents that support the '${scope}' scope. Space toggles; 'a' selects all.`
    )
  );

  const projectRoot = process.cwd();
  const candidates = registry.agents.agents
    .filter((a) => a.scopes.includes(scope))
    .sort((a, b) => a.id.localeCompare(b.id));

  const excluded = registry.agents.agents.filter((a) => !a.scopes.includes(scope));
  if (excluded.length > 0) {
    process.stdout.write(
      `  ${paint(
        `Note: ${excluded.map((a) => a.name).join(', ')} do not support the '${scope}' scope.`,
        'warn'
      )}\n`
    );
  }

  // Legend. Uses both colour and a marker so it reads even without colour.
  process.stdout.write(
    `  ${paint('\u2713 installed', 'ok')}   ${paint('\u00b7 not installed', 'warn')}\n\n`
  );

  const choices = [
    ...candidates.map((a) => {
      const det = detectAgent(a, projectRoot);
      const mark = det.installed ? '\u2713' : '\u00b7';
      const status = det.installed ? 'installed' : 'not installed';
      // Plain name only: ANSI in a choice name breaks arrow-key navigation.
      return {
        name: `${mark} ${a.name}  [${a.supportLevel}]  ${status}`,
        value: a.id,
      };
    }),
    { name: '\u2190 Back', value: '__back__' },
  ];

  const picked = await plainCheckbox<string>({
    message: 'Select the AI agents to install into',
    pageSize: 14,
    choices,
  });

  if (picked.includes('__back__') && picked.length === 1) return 'back';
  const agentIds = picked.filter((v) => v !== '__back__');

  // Offer install links for any selected agent that is not installed.
  for (const id of agentIds) {
    const agent = registry.agents.agents.find((a) => a.id === id)!;
    const det = detectAgent(agent, projectRoot);
    if (det.installed) continue;

    const url = agentInstallUrl(agent);
    if (!url) continue;

    process.stdout.write(
      `\n  ${paint(`${agent.name} does not look installed.`, 'warn')}\n` +
        `  ${paint(url, 'dim')}\n`
    );
    const open = await confirm({
      message: `Open the ${agent.name} installer page in your browser?`,
      default: false,
    });
    if (open) {
      const ok = openUrl(url);
      process.stdout.write(
        ok
          ? `  ${paint('Opened in your browser.', 'ok')}\n\n`
          : `  ${paint('Could not open a browser; visit the URL above.', 'warn')}\n\n`
      );
    }
  }

  return { agentIds };
}
