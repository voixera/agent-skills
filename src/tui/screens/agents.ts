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

import { checkbox, confirm } from '@inquirer/prompts';
import type { Registry, Scope } from '../../types';
import { section, paint } from '../components/theme';
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

  const choices = [
    ...candidates.map((a) => {
      const det = detectAgent(a, projectRoot);
      const status = det.installed ? paint('[installed]', 'ok') : paint('[not installed]', 'warn');
      return {
        name: `${a.name}  ${paint(`[${a.supportLevel}]`, 'dim')}  ${status}`,
        value: a.id,
      };
    }),
    { name: paint('\u2190 Back', 'dim'), value: '__back__' },
  ];

  const picked = await checkbox({
    message: 'Select the AI agents to install into',
    instructions: '\u2191/\u2193 to navigate  \u2022  Space: select  \u2022  Enter: confirm',
    choices,
    pageSize: 14,
    required: false,
    validate: (choices) => {
      const values = choices.map((c) => c.value);
      if (values.includes('__back__')) return true;
      if (values.length === 0) return 'Select at least one agent (or choose Back).';
      return true;
    },
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
