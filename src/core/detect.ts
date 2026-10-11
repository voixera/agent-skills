/**
 * Agent detection (core).
 *
 * Scans the filesystem for each agent's `detect` markers to work out whether the
 * agent is installed on this machine. Pure and side-effect free: it only reads.
 * The TUI uses it to show installed/not-installed state and to offer a link to
 * an agent's installer.
 */

import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import type { AgentDefinition, Registry } from '../types';

export interface AgentDetection {
  agent: AgentDefinition;
  installed: boolean;
  /** Markers that were found, e.g. ["~/.codex", "~/.codex/config.toml"]. */
  matched: string[];
  /** Where the URL should open: the agent's install docs page. */
  installUrl: string;
}

function expand(marker: string, projectRoot: string): string {
  if (marker.startsWith('~')) {
    return path.join(os.homedir(), marker.replace(/^~[\\/]?/, ''));
  }
  return path.join(projectRoot, marker);
}

/** Install / setup page for an agent (used when it is not installed). */
export function agentInstallUrl(agent: AgentDefinition): string {
  // Prefer an explicit install page if recorded; otherwise fall back to docs.
  const explicit = (agent as { installUrl?: string }).installUrl;
  return explicit ?? agent.docs ?? '';
}

export function detectAgent(agent: AgentDefinition, projectRoot: string): AgentDetection {
  const matched: string[] = [];
  for (const marker of agent.detect ?? []) {
    if (fs.existsSync(expand(marker, projectRoot))) {
      matched.push(marker);
    }
  }
  return {
    agent,
    installed: matched.length > 0,
    matched,
    installUrl: agentInstallUrl(agent),
  };
}

export function detectAll(registry: Registry, projectRoot: string): AgentDetection[] {
  return registry.agents.agents
    .map((a) => detectAgent(a, projectRoot))
    .sort((a, b) => a.agent.name.localeCompare(b.agent.name));
}

/**
 * Open a URL in the user's default browser. Returns true when a launcher was
 * invoked. Best-effort; never throws.
 */
export function openUrl(url: string): boolean {
  if (!url) return false;
  const { spawnSync } = require('node:child_process') as typeof import('node:child_process');
  try {
    if (process.platform === 'win32') {
      // start is a shell builtin; use cmd /c.
      spawnSync('cmd', ['/c', 'start', '', url], { windowsHide: true });
    } else if (process.platform === 'darwin') {
      spawnSync('open', [url]);
    } else {
      spawnSync('xdg-open', [url]);
    }
    return true;
  } catch {
    return false;
  }
}
