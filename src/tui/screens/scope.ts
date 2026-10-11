/**
 * SCREEN B - Installation scope.
 *
 * Choose project, user, or a custom path. Each option explains its consequence.
 */

import { select, input } from '@inquirer/prompts';
import * as path from 'node:path';
import * as fs from 'node:fs';
import type { Registry, Scope } from '../../types';
import { section } from '../components/theme';
import { homeDirectory } from '../../core/manifest';

export interface ScopeChoice {
  scope: Scope;
  projectRoot: string;
  displayPath: string;
}

export async function scopeScreen(_registry: Registry): Promise<ScopeChoice | 'back'> {
  process.stdout.write(section('Installation scope', 'Where should the skills be written?'));

  const cwd = process.cwd();
  const home = homeDirectory();

  const choice = await select({
    message: 'Scope',
    loop: false,
    choices: [
      {
        name: `This project\n      ${cwd}\n      Skills are written into this folder and can be committed with your code.`,
        value: 'project' as const,
      },
      {
        name: `My user profile\n      ${home}\n      Skills apply to every project for your account. Not committed.`,
        value: 'user' as const,
      },
      {
        name: 'Custom path\n      Choose another folder to install into.',
        value: 'custom' as const,
      },
      { name: 'Back', value: 'back' as const },
    ],
  });

  if (choice === 'back') return 'back';

  if (choice === 'project') {
    return { scope: 'project', projectRoot: cwd, displayPath: cwd };
  }

  if (choice === 'user') {
    return { scope: 'user', projectRoot: cwd, displayPath: home };
  }

  // Custom path.
  const answer = await input({
    message: 'Custom project path',
    default: cwd,
    validate: (value) => {
      const resolved = path.resolve(value.trim());
      if (!fs.existsSync(resolved)) return `Path does not exist: ${resolved}`;
      if (!fs.statSync(resolved).isDirectory()) return `Not a directory: ${resolved}`;
      return true;
    },
  });
  const resolved = path.resolve(answer.trim());
  return { scope: 'project', projectRoot: resolved, displayPath: resolved };
}
