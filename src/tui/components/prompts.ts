/**
 * Shared prompt wrappers.
 *
 * Centralises the checkbox/select configuration so every screen behaves the
 * same and avoids the settings that make @inquirer/prompts misbehave
 * (multi-line or ANSI choice names, oversized pageSize, custom instruction
 * strings). Screens call these instead of the raw prompts.
 */

import { checkbox, select } from '@inquirer/prompts';

/** A single-line, plain-text choice. */
export interface PlainChoice<T> {
  name: string;
  value: T;
  checked?: boolean;
  description?: string;
}

/**
 * A checkbox with safe defaults: plain names, a page size that fits, and the
 * library's own key hints (no custom instruction strings).
 */
export async function plainCheckbox<T>(options: {
  message: string;
  choices: PlainChoice<T>[];
  pageSize?: number;
}): Promise<T[]> {
  return checkbox<T>({
    message: options.message,
    choices: options.choices.map((c) => ({
      name: c.name,
      value: c.value,
      checked: c.checked,
      description: c.description,
    })),
    pageSize: options.pageSize ?? 10,
    loop: true,
    required: false,
  });
}

/** A single-select with the same safe defaults. */
export async function plainSelect<T>(options: {
  message: string;
  choices: PlainChoice<T>[];
  pageSize?: number;
}): Promise<T> {
  return select<T>({
    message: options.message,
    choices: options.choices.map((c) => ({
      name: c.name,
      value: c.value,
      description: c.description,
    })),
    pageSize: options.pageSize ?? 10,
    loop: false,
  });
}
