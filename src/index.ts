/**
 * Agent Skills - programmatic entry.
 *
 * The executable entry point is bin/agentskillsmd.js, which requires
 * dist/cli/entry.js. This file re-exports the core for programmatic use.
 */

export * from './core/core';
export { runApp } from './tui/app';
