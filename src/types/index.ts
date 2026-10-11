/**
 * Shared types for the Agent Skills TUI and core.
 *
 * These types mirror the on-disk registry (registry/*.json). They are the
 * contract between the TUI (interface) and the core (logic); the TUI never
 * reaches into the registry or filesystem directly.
 */

export type Scope = 'project' | 'user';

export type AgentSupportLevel = 'native' | 'rules' | 'instructions';
export type AgentEvidence = 'verified' | 'documented';
export type AgentFormat =
  | 'skill-md'
  | 'mdc-frontmatter'
  | 'instructions-md'
  | 'markdown-rules'
  | 'aggregated-instructions';

export interface AgentDefinition {
  id: string;
  name: string;
  adapter: string;
  supportLevel: AgentSupportLevel;
  evidence: AgentEvidence;
  scopes: Scope[];
  features: string[];
  paths: Partial<Record<Scope, string>>;
  detect?: string[];
  format: AgentFormat;
  limitations?: string[];
  docs?: string;
  installUrl?: string;
}

export interface AgentsRegistry {
  version: string;
  updated?: string;
  notes?: string[];
  agents: AgentDefinition[];
}

export interface SkillEntry {
  id: string;
  name: string;
  description: string;
  category: string;
  version: string;
  path: string;
  agents: string[];
  depends: string[];
  tools: string[];
}

export interface SkillsRegistry {
  version: string;
  updated?: string;
  notes?: string[];
  skills: SkillEntry[];
}

export interface PresetEntry {
  id: string;
  name: string;
  description: string;
  skills: string[];
}

export interface PresetsRegistry {
  version: string;
  updated?: string;
  notes?: string[];
  presets: PresetEntry[];
}

export interface Registry {
  agents: AgentsRegistry;
  skills: SkillsRegistry;
  presets: PresetsRegistry;
}

/** A single file operation decided by the installer engine. */
export interface PlanAction {
  kind: 'file' | 'managed-block';
  agentId: string;
  skillId: string;
  skillVersion: string;
  destination: string;
  relativePath: string;
  action: 'create' | 'overwrite' | 'unchanged';
  format: AgentFormat;
}

export interface PlanDiagnostic {
  status: 'PASS' | 'FAIL' | 'WARN' | 'SKIP';
  name: string;
  message: string;
  reason?: string;
  category: string;
}

export interface InstallPlan {
  scope: Scope;
  projectRoot: string;
  scopeRoot: string;
  agents: string[];
  requested: string[];
  resolved: string[];
  addedDependencies: string[];
  actions: PlanAction[];
  diagnostics: PlanDiagnostic[];
}

export interface InstallResult {
  status: 'PASS' | 'FAIL' | 'WARN' | 'SKIP';
  name: string;
  message: string;
  reason?: string;
  category: string;
}

/** The choices the user makes in the TUI. */
export interface UserSelection {
  scope: Scope;
  projectRoot: string;
  agentIds: string[];
  skillIds: string[];
  presetId?: string;
}

export interface CompletionSummary {
  exitCode: number;
  created: number;
  updated: number;
  unchanged: number;
  skipped: number;
  failed: number;
  warnings: number;
  results: InstallResult[];
}
