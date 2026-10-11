/**
 * Skill content reader (core).
 *
 * Reads a canonical SKILL.md from the repo, splitting YAML frontmatter from the
 * body. Rendered output is stable across releases.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { SkillEntry } from '../types';
import { resolvePackageRoot } from './registry';

export interface SkillContent {
  skill: SkillEntry;
  path: string;
  frontmatter: Record<string, unknown>;
  body: string;
  raw: string;
  hasFrontmatter: boolean;
}

/** Minimal frontmatter parser for the subset the repo uses. */
export function parseFrontmatter(content: string): {
  frontmatter: Record<string, unknown>;
  body: string;
  hasFrontmatter: boolean;
} {
  const normalised = content.replace(/\r\n/g, '\n');
  if (!/^\s*---\s*\n/.test(normalised)) {
    return { frontmatter: {}, body: content, hasFrontmatter: false };
  }

  const lines = normalised.split('\n');
  let endIndex = -1;
  for (let i = 1; i < lines.length; i++) {
    if (/^\s*---\s*$/.test(lines[i])) {
      endIndex = i;
      break;
    }
  }
  if (endIndex < 0) {
    return { frontmatter: {}, body: content, hasFrontmatter: false };
  }

  const fmLines = lines.slice(1, endIndex);
  const body = lines.slice(endIndex + 1).join('\n').replace(/^\n+/, '');
  const frontmatter: Record<string, unknown> = {};

  let currentMap: string | null = null;
  for (const raw of fmLines) {
    if (!raw.trim() || /^\s*#/.test(raw)) continue;

    const nested = raw.match(/^\s+([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (nested && currentMap) {
      const key = nested[1];
      (frontmatter[currentMap] as Record<string, unknown>)[key] = scalar(nested[2]);
      continue;
    }

    const top = raw.match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (top) {
      const key = top[1];
      const val = top[2];
      if (val.trim() === '') {
        currentMap = key;
        frontmatter[key] = {};
      } else {
        currentMap = null;
        frontmatter[key] = scalar(val);
      }
    }
  }

  return { frontmatter, body, hasFrontmatter: true };
}

function scalar(value: string): unknown {
  let v = value.trim();
  if (v.length >= 2 && ((v[0] === '"' && v[v.length - 1] === '"') || (v[0] === "'" && v[v.length - 1] === "'"))) {
    v = v.slice(1, -1);
  }
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v === 'null') return null;
  return v;
}

export function skillFilePath(skill: SkillEntry): string {
  const root = resolvePackageRoot();
  return path.join(root, ...skill.path.split('/'));
}

export function readSkillContent(skill: SkillEntry): SkillContent {
  const file = skillFilePath(skill);
  if (!fs.existsSync(file)) {
    throw new Error(`Skill '${skill.id}' points at a missing file: ${skill.path}`);
  }
  const raw = fs.readFileSync(file, 'utf8');
  const parsed = parseFrontmatter(raw);
  return {
    skill,
    path: file,
    frontmatter: parsed.frontmatter,
    body: parsed.body,
    raw,
    hasFrontmatter: parsed.hasFrontmatter,
  };
}
