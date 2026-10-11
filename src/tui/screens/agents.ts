/**
 * SCREEN C - AI agent selection.
 *
 * Multi-select of supported agents, filtered by the chosen scope. Shows the
 * support level and evidence so we never imply an agent is verified when it is
 * only documented.
 */

import { checkbox } from '@inquirer/prompts';
import type { Registry, Scope } from '../../types';
import { section, paint } from '../components/theme';

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
      const verified = a.evidence === 'verified' ? paint('verified', 'ok') : paint('documented', 'warn');
      return {
        name: `${a.name}  ${paint(`[${a.supportLevel}]`, 'dim')}  ${verified}`,
        value: a.id,
        checked: a.evidence === 'verified',
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
  return { agentIds: picked.filter((v) => v !== '__back__') };
}
