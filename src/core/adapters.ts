/**
 * Adapters (core).
 *
 * Renders canonical skill content into each agent's on-disk format, and manages
 * the shared "managed block" used by aggregated-instruction agents. The output
 * shape must stay stable across releases.
 */

import type { AgentDefinition, AgentFormat } from '../types';
import type { SkillContent } from './skill-content';

export const MANAGED_BLOCK_MARKERS = {
  begin: '<!-- agent-skills:begin -->',
  end: '<!-- agent-skills:end -->',
} as const;

/** One-line description of what each format produces, for the UI. */
export const FORMAT_DESCRIPTIONS: Record<AgentFormat, string> = {
  'skill-md': 'native skill file (<dir>/<skillId>/SKILL.md)',
  'mdc-frontmatter': 'Cursor rule (.mdc with description/globs/alwaysApply)',
  'instructions-md': 'Copilot instruction (*.instructions.md with applyTo)',
  'markdown-rules': 'markdown rule document',
  'aggregated-instructions': 'shared managed block in one file',
};

export function renderSkillMd(content: SkillContent): string {
  const s = content.skill;
  return (
    '---\n' +
    `name: ${s.id}\n` +
    `description: ${s.description}\n` +
    'metadata:\n' +
    `  category: ${s.category}\n` +
    `  version: ${s.version}\n` +
    '  agents: all\n' +
    '---\n\n' +
    content.body.replace(/^\n+/, '')
  );
}

export function renderMdcRule(content: SkillContent): string {
  const s = content.skill;
  const desc = s.description.replace(/"/g, '\\"');
  return (
    '---\n' +
    `description: ${desc}\n` +
    'globs:\n' +
    'alwaysApply: false\n' +
    '---\n\n' +
    `# ${s.name}\n\n` +
    content.body.replace(/\s+$/, '') +
    '\n'
  );
}

export function renderInstructionsMd(content: SkillContent): string {
  const s = content.skill;
  return (
    '---\n' +
    'applyTo: "**"\n' +
    '---\n\n' +
    `# ${s.name}\n\n` +
    content.body.replace(/\s+$/, '') +
    '\n'
  );
}

export function renderMarkdownRule(content: SkillContent): string {
  const s = content.skill;
  return (
    `# ${s.name}\n\n` +
    `> Generated from the Agent Skills skill \`${s.id}\` (v${s.version}).\n\n` +
    content.body.replace(/\s+$/, '') +
    '\n'
  );
}

/** Render a skill for a given agent format. */
export function renderForAgent(content: SkillContent, agent: AgentDefinition): string {
  switch (agent.format) {
    case 'skill-md':
      return renderSkillMd(content);
    case 'mdc-frontmatter':
      return renderMdcRule(content);
    case 'instructions-md':
      return renderInstructionsMd(content);
    case 'markdown-rules':
      return renderMarkdownRule(content);
    case 'aggregated-instructions':
      return renderMarkdownRule(content);
    default: {
      const never: never = agent.format;
      throw new Error(`No renderer for format '${never}' (agent '${agent.id}').`);
    }
  }
}

export function buildManagedBlock(contents: SkillContent[], toolVersion: string): string {
  const { begin, end } = MANAGED_BLOCK_MARKERS;
  const parts: string[] = [];
  parts.push(begin);
  parts.push(
    `<!-- Managed by Agent Skills v${toolVersion}. Do not edit inside these markers; uninstall removes only this block. -->`
  );
  parts.push('');
  parts.push('# Agent Skills');
  parts.push('');
  parts.push('The following skills are installed. Read and follow them when relevant.');
  for (const c of contents) {
    parts.push('');
    parts.push('---');
    parts.push('');
    parts.push(`## ${c.skill.name}`);
    parts.push('');
    parts.push(c.body.replace(/\s+$/, ''));
  }
  parts.push('');
  parts.push(end);
  return parts.join('\n') + '\n';
}

/**
 * Merge a managed block into existing file content. Non-destructive: only the
 * region between the markers is replaced; surrounding content is preserved.
 */
export function mergeManagedBlock(existing: string | null, block: string): string {
  const { begin, end } = MANAGED_BLOCK_MARKERS;
  if (!existing) return block.replace(/\s+$/, '') + '\n';

  const beginIdx = existing.indexOf(begin);
  const endIdx = existing.indexOf(end);
  if (beginIdx >= 0 && endIdx > beginIdx) {
    const before = existing.slice(0, beginIdx);
    const after = existing.slice(endIdx + end.length);
    return before + block.replace(/\s+$/, '') + after;
  }
  return existing.replace(/\s+$/, '') + '\n\n' + block.replace(/\s+$/, '') + '\n';
}

export function removeManagedBlock(existing: string | null): { content: string; removed: boolean } {
  const { begin, end } = MANAGED_BLOCK_MARKERS;
  if (!existing) return { content: '', removed: false };
  const beginIdx = existing.indexOf(begin);
  const endIdx = existing.indexOf(end);
  if (beginIdx < 0 || endIdx <= beginIdx) return { content: existing, removed: false };
  const before = existing.slice(0, beginIdx);
  const after = existing.slice(endIdx + end.length);
  return { content: before.replace(/\s+$/, '') + after.replace(/^\s+/, ''), removed: true };
}
