import type { ModelRegistry } from "@earendil-works/pi-coding-agent";
import { Data } from "effect";

/** Who initiated the session. User asides stay out of model-facing tooling. */
export type SubagentOrigin = "model" | "btw";

/**
 * Shared reasoning-effort scale (pi's thinking levels). The pi backend uses it
 * directly as its native thinking level. Omitted = inherit the parent level.
 */
export const REASONING_EFFORTS = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] as const;
export type ReasoningEffort = (typeof REASONING_EFFORTS)[number];

export type SubagentStatus = "running" | "done" | "error";

/** Parent-session context resolved by the tool layer and passed opaquely. */
export interface ParentContext {
  readonly parentCwd: string;
  readonly projectTrusted: boolean;
  /** Parent pi model, for the pi backend's "inherit" default. */
  readonly inheritedModel?: { readonly provider: string; readonly id: string };
  readonly inheritedThinkingLevel?: string;
  /** Parent model registry; required by the pi backend to resolve models. */
  readonly modelRegistry?: ModelRegistry;
}

export interface SpawnTask {
  /** Omitted for normal tool-driven spawns. */
  readonly origin?: SubagentOrigin;
  readonly prompt: string;
  readonly title: string;
  readonly cwd: string;
  /**
   * Model hint for the pi backend: "provider/model-id" or bare model id.
   * Omitted = inherit the parent session's model.
   */
  readonly model?: string;
  /** Shared effort scale; the pi backend uses it directly as thinking level. */
  readonly reasoningEffort?: ReasoningEffort;
  readonly parent: ParentContext;
}

export interface SubagentMeta {
  readonly backend: "pi";
  /** Active provider/model label. */
  readonly modelLabel?: string;
  /** Context window capacity for utilization display, when known. */
  readonly contextWindow?: number;
  /** pi session file for the subagent. */
  readonly sessionFilePath?: string;
}

export type RunOutcome =
  | { readonly _tag: "Completed"; readonly finalText: string }
  | {
      readonly _tag: "Failed";
      readonly errorText: string;
      readonly partialText?: string;
    }
  | { readonly _tag: "Interrupted"; readonly partialText?: string };

/** Events needed by status tools and result delivery. Pi persists the full transcript. */
export type SubagentEvent =
  | { readonly _tag: "RunStarted" }
  | { readonly _tag: "RunSettled"; readonly outcome: RunOutcome }
  | { readonly _tag: "AssistantDelta"; readonly delta: string }
  | { readonly _tag: "AssistantMessage" }
  | {
      readonly _tag: "UsageChanged";
      readonly tokens?: number;
      readonly contextWindow?: number;
    }
  | { readonly _tag: "MetaChanged"; readonly meta: Partial<SubagentMeta> };

// --- Snapshot ---------------------------------------------------------------

/**
 * The manager folds `SubagentEvent`s into one snapshot per subagent. This is
 * everything the status and result tools read.
 */
export interface SubagentSnapshot {
  readonly id: string;
  readonly origin: SubagentOrigin;
  readonly backend: "pi";
  readonly title: string;
  readonly prompt: string;
  readonly cwd: string;
  readonly status: SubagentStatus;
  readonly createdAt: number;
  readonly settledAt?: number;
  readonly errorText?: string;
  readonly meta: SubagentMeta;
  readonly usage: { readonly tokens?: number; readonly contextWindow?: number };
  /** Streaming text, cleared when the finalized message lands. */
  readonly liveText?: string;
  /** Final text of the most recent completed run. */
  readonly finalText: string;
  /** Count of finalized assistant messages (for subagent_check). */
  readonly turns: number;
}

/** Final text, or the live streaming buffer while a run is active. */
export function latestText(snap: SubagentSnapshot) {
  const live = snap.liveText?.trim();
  if (live) return live;
  return snap.finalText;
}

export function formatElapsed(snap: SubagentSnapshot) {
  const end = snap.settledAt ?? Date.now();
  const totalSeconds = Math.max(0, Math.round((end - snap.createdAt) / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes > 0
    ? `${minutes}m${seconds.toString().padStart(2, "0")}s`
    : `${seconds}s`;
}

// --- Errors -------------------------------------------------------------------

export class SpawnError extends Data.TaggedError("SpawnError")<{
  readonly message: string;
}> {}

export class ConcurrencyLimitError extends Data.TaggedError(
  "ConcurrencyLimitError",
)<{
  readonly message: string;
}> {}
