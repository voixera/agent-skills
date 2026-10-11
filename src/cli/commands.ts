/**
 * Advanced list/agent/preset/validate commands. These are optional; the default
 * experience is the TUI.
 */

import { loadRegistry, loadAndValidateRegistry, skillsByCategory } from '../core/registry';
import { paint } from '../tui/components/theme';

export function runList(flags: Record<string, string | true>): number {
  const reg = loadRegistry();
  const category = flags.category as string | undefined;
  const search = flags.search as string | undefined;

  let skills = reg.skills.skills;
  if (category) skills = skills.filter((s) => s.category === category);
  if (search) {
    const n = search.toLowerCase();
    skills = skills.filter(
      (s) =>
        s.id.toLowerCase().includes(n) ||
        s.name.toLowerCase().includes(n) ||
        s.description.toLowerCase().includes(n)
    );
  }

  if (skills.length === 0) {
    process.stdout.write('No skills matched.\n');
    return 4;
  }

  process.stdout.write(`\n  ${paint('ID'.padEnd(34), 'brand')}${paint('CATEGORY'.padEnd(12), 'brand')}NAME\n`);
  for (const s of skills.sort((a, b) => a.category.localeCompare(b.category) || a.id.localeCompare(b.id))) {
    process.stdout.write(`  ${s.id.padEnd(34)}${s.category.padEnd(12)}${s.name}\n`);
  }
  process.stdout.write(`\n  ${skills.length} skill(s).\n`);
  return 0;
}

export function runAgents(): number {
  const reg = loadRegistry();
  process.stdout.write(`\n  ${paint('ID'.padEnd(18), 'brand')}${paint('SUPPORT'.padEnd(14), 'brand')}${paint('EVIDENCE'.padEnd(12), 'brand')}NAME\n`);
  for (const a of [...reg.agents.agents].sort((x, y) => x.id.localeCompare(y.id))) {
    const ev = a.evidence === 'verified' ? paint(a.evidence, 'ok') : paint(a.evidence, 'warn');
    process.stdout.write(`  ${a.id.padEnd(18)}${a.supportLevel.padEnd(14)}${ev}${' '.repeat(Math.max(0, 12 - a.evidence.length))}${a.name}\n`);
  }
  process.stdout.write('\n');
  return 0;
}

export function runPresets(): number {
  const reg = loadRegistry();
  for (const p of [...reg.presets.presets].sort((x, y) => x.id.localeCompare(y.id))) {
    process.stdout.write(`\n  ${paint(p.name, 'brand')}  ${paint(`(${p.skills.length})`, 'dim')}\n`);
    process.stdout.write(`    ${p.description}\n`);
  }
  process.stdout.write('\n');
  return 0;
}

export function runValidate(): number {
  try {
    const reg = loadAndValidateRegistry();
    const cats = skillsByCategory(reg);
    process.stdout.write(
      `\n  ${paint('PASS', 'ok')} registry valid: ${reg.skills.skills.length} skills, ` +
        `${reg.agents.agents.length} agents, ${reg.presets.presets.length} presets, ${cats.size} categories.\n\n`
    );
    return 0;
  } catch (err) {
    process.stderr.write(`\n  ${paint('FAIL', 'error')} ${(err as Error).message}\n`);
    const problems = (err as { problems?: string[] }).problems;
    if (problems) for (const p of problems) process.stderr.write(`    - ${p}\n`);
    return 1;
  }
}
