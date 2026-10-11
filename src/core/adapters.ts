/**
 * Adapter metadata shared by the TypeScript core.
 *
 * The authoritative adapter definitions live in registry/agents.json and are
 * executed by the PowerShell engine. This module only exposes constants the
 * TUI/planner need (managed-block markers) and helper text.
 */

export const MANAGED_BLOCK_MARKERS = {
  begin: '<!-- agent-skills:begin -->',
  end: '<!-- agent-skills:end -->',
} as const;

/** One-line description of what each format produces, for the UI. */
export const FORMAT_DESCRIPTIONS: Record<string, string> = {
  'skill-md': 'native skill file (<dir>/<skillId>/SKILL.md)',
  'mdc-frontmatter': 'Cursor rule (.mdc with description/globs/alwaysApply)',
  'instructions-md': 'Copilot instruction (*.instructions.md with applyTo)',
  'markdown-rules': 'markdown rule document',
  'aggregated-instructions': 'shared managed block in one file',
};
