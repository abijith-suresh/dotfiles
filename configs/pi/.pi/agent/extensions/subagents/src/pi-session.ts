/** One headless Pi SDK session per task, with trust gating and no child delegation. */

import type { AssistantMessage, Model } from "@earendil-works/pi-ai";
import type {
  AgentSession,
  AgentSessionEvent,
  ModelRegistry,
} from "@earendil-works/pi-coding-agent";
import {
  createAgentSession,
  DefaultResourceLoader,
  getAgentDir,
  SessionManager,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";
import {
  withAbort,
  withDeadline,
  type SpawnSession,
  type SubagentSession,
} from "./backend.ts";
import type { SubagentEvent, SubagentMeta } from "./domain.ts";
import { createToolCallTimeoutGuard } from "./tool-call-timeout.ts";

const CHILD_SHUTDOWN_TIMEOUT_MS = 5_000;

/** Tools that headless children must not receive. Everything else stays enabled. */
const CHILD_EXCLUDED_TOOL_NAMES = [
  "subagent_spawn",
  "subagent_wait",
  "subagent_cancel",
  "subagent_check",
  "subagent_list",
  "workflow",
  "ask_user",
] as const;

// --- Model + effort resolution -----------------------------------------------

type ThinkingLevel = NonNullable<
  NonNullable<Parameters<typeof createAgentSession>[0]>["thinkingLevel"]
>;

/**
 * Resolve the generic model hint against the parent registry:
 * "provider/model-id" is exact; a bare id prefers the inherited provider,
 * then must be unambiguous across providers. No hint inherits the parent
 * model; with nothing to inherit, the SDK default applies.
 */
function resolvePiModel(
  registry: ModelRegistry,
  hint: string | undefined,
  inherited: { provider: string; id: string } | undefined,
): Model<any> | undefined {
  if (!hint) {
    if (!inherited) return undefined;
    return registry.find(inherited.provider, inherited.id) ?? undefined;
  }
  const slash = hint.indexOf("/");
  if (slash > 0) {
    const provider = hint.slice(0, slash);
    const id = hint.slice(slash + 1);
    const found = registry.find(provider, id);
    if (found) return found;
    throw new Error(`Unknown model "${hint}".`);
  }
  if (inherited) {
    const found = registry.find(inherited.provider, hint);
    if (found) return found;
  }
  const matches = registry.getAll().filter((m) => m.id === hint);
  if (matches.length === 1) return matches[0];
  if (matches.length > 1) {
    throw new Error(
      `Model "${hint}" exists in multiple providers (${matches.map((m) => m.provider).join(", ")}). Use "provider/${hint}".`,
    );
  }
  throw new Error(`Unknown model "${hint}".`);
}

// --- Child session lifecycle -----------------------------------------------

/** Load normal global/package resources and trust-gated project resources. */
async function createChildResources(cwd: string, projectTrusted: boolean) {
  const agentDir = getAgentDir();
  const settingsManager = SettingsManager.create(cwd, agentDir, {
    projectTrusted,
  });
  const loader = new DefaultResourceLoader({ cwd, agentDir, settingsManager });
  await loader.reload();
  return { loader, settingsManager };
}

/** Emit child session_shutdown (bounded), then dispose. Never throws. */
async function shutdownAndDisposeChildSession(session: AgentSession) {
  try {
    if (session.extensionRunner.hasHandlers("session_shutdown")) {
      await withDeadline(
        session.extensionRunner.emit({
          type: "session_shutdown",
          reason: "quit",
        }),
        CHILD_SHUTDOWN_TIMEOUT_MS,
      );
    }
  } catch {
    // Extension runner inspection/emission is best-effort during teardown.
  } finally {
    try {
      session.dispose();
    } catch {
      // Disposal is terminal and must remain idempotent for callers.
    }
  }
}

// --- Event translation ----------------------------------------------------------

function lastAssistantMessage(
  session: AgentSession,
): AssistantMessage | undefined {
  const messages = session.messages;
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role === "assistant") return msg;
  }
  return undefined;
}

/** Final assistant text output (last assistant message with text). */
function finalOutput(session: AgentSession): string {
  const messages = session.messages;
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role !== "assistant") continue;
    const text = msg.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n")
      .trim();
    if (text) return text;
  }
  return "";
}

function boundedError(error: unknown) {
  return (error instanceof Error ? error.message : String(error)).slice(
    0,
    4096,
  );
}

const createPiSession: SpawnSession = async (task, signal) => {
  signal?.throwIfAborted();
  const registry = task.parent.modelRegistry;
  if (!registry)
    throw new Error("pi backend requires the parent session's model registry.");
  const model = resolvePiModel(
    registry,
    task.model,
    task.parent.inheritedModel,
  );
  const thinkingLevel = (task.reasoningEffort ??
    task.parent.inheritedThinkingLevel) as ThinkingLevel | undefined;
  const { loader, settingsManager } = await createChildResources(
    task.cwd,
    task.parent.projectTrusted,
  );
  signal?.throwIfAborted();
  const { session } = await createAgentSession({
    cwd: task.cwd,
    sessionManager: SessionManager.create(task.cwd),
    settingsManager,
    resourceLoader: loader,
    model,
    thinkingLevel,
    excludeTools: [...CHILD_EXCLUDED_TOOL_NAMES],
  });
  try {
    await session.bindExtensions({ mode: "print" });
    signal?.throwIfAborted();
  } catch (error) {
    await shutdownAndDisposeChildSession(session);
    throw error;
  }

  const state = {
    closed: false,
    /** prompt() rejection for the active run; folded into RunSettled. */
    runError: undefined as string | undefined,
    /** One terminal event per run: lifecycle, prompt-rejection, and abort
     * fallbacks can all race to settle; the first wins. */
    settled: false,
  };

  let listener: ((event: SubagentEvent) => void) | undefined;
  const emit = (event: SubagentEvent) => listener?.(event);

  const toolTimeout = createToolCallTimeoutGuard();
  toolTimeout.apply(session);

  const activeModel = (): Model<any> | undefined => {
    const sessionModel = session.model;
    const last = lastAssistantMessage(session);
    if (!last) return sessionModel;
    if (
      sessionModel &&
      (last.provider !== sessionModel.provider ||
        last.model !== sessionModel.id)
    ) {
      // The session changed models after this assistant response.
      return sessionModel;
    }
    return (
      registry.find(last.provider, last.responseModel ?? last.model) ??
      sessionModel
    );
  };

  const currentMeta = (): SubagentMeta => {
    const m = activeModel();
    return {
      backend: "pi",
      modelLabel: m ? `${m.provider}/${m.id}` : undefined,
      contextWindow: m?.contextWindow,
      sessionFilePath: session.sessionFile,
    };
  };

  const emitUsage = () => {
    const usage = session.getContextUsage();
    emit({
      _tag: "UsageChanged",
      tokens: usage?.tokens ?? undefined,
      contextWindow: activeModel()?.contextWindow ?? usage?.contextWindow,
    });
  };

  const settle = () => {
    if (state.settled) return;
    state.settled = true;
    const last = lastAssistantMessage(session);
    const partialText = finalOutput(session) || undefined;
    if (last?.stopReason === "aborted") {
      emit({
        _tag: "RunSettled",
        outcome: { _tag: "Interrupted", partialText },
      });
      return;
    }
    const errorText =
      state.runError ??
      (last?.stopReason === "error"
        ? (last.errorMessage ?? "Run failed")
        : undefined);
    if (errorText !== undefined) {
      emit({
        _tag: "RunSettled",
        outcome: {
          _tag: "Failed",
          errorText: boundedError(errorText),
          partialText,
        },
      });
      return;
    }
    emit({
      _tag: "RunSettled",
      outcome: { _tag: "Completed", finalText: finalOutput(session) },
    });
  };

  const handleEvent = (event: AgentSessionEvent) => {
    if (state.closed) return;
    switch (event.type) {
      case "agent_start":
        // Extensions may register tools between runs; guard new ones too.
        toolTimeout.apply(session);
        state.settled = false;
        break;
      case "message_update": {
        const streamEvent = event.assistantMessageEvent;
        if (streamEvent.type === "text_delta") {
          emit({
            _tag: "AssistantDelta",
            delta: streamEvent.delta,
          });
        }
        break;
      }
      case "message_end":
        if (event.message.role === "assistant") {
          emit({ _tag: "AssistantMessage" });
          emitUsage();
          emit({ _tag: "MetaChanged", meta: currentMeta() });
        }
        break;
      case "agent_settled":
        settle();
        break;
    }
  };
  let unsubscribe: (() => void) | undefined;
  let disposal: Promise<void> | undefined;
  return {
    meta: currentMeta,
    start(onEvent) {
      listener = onEvent;
      unsubscribe = session.subscribe(handleEvent);
      try {
        session.sessionManager.appendSessionInfo(
          `${task.origin === "btw" ? "btw" : "subagent"}: ${task.title}`,
        );
      } catch {
        // Naming must not prevent a task from starting.
      }
      emit({ _tag: "MetaChanged", meta: currentMeta() });
      void session.prompt(task.prompt).catch((error) => {
        if (state.closed) return;
        state.runError = boundedError(error);
        // Preflight errors never start the agent lifecycle.
        if (!session.isStreaming) settle();
      });
    },
    async interrupt() {
      if (state.closed) return;
      try {
        session.clearQueue();
      } catch {
        /* Abort regardless. */
      }
      await session.abort().catch(() => undefined);
      // The manager bounds this wait and force-disposes if the child hangs.
      await session.waitForIdle();
      if (!state.closed && !state.settled) {
        state.settled = true;
        emit({ _tag: "RunSettled", outcome: { _tag: "Interrupted" } });
      }
    },
    dispose() {
      disposal ??= (async () => {
        state.closed = true;
        unsubscribe?.();
        try {
          session.clearQueue();
        } catch {
          /* Continue with disposal. */
        }
        await withDeadline(session.abort(), CHILD_SHUTDOWN_TIMEOUT_MS).catch(
          () => {},
        );
        await shutdownAndDisposeChildSession(session);
      })();
      return disposal;
    },
  } satisfies SubagentSession;
};

export const spawnPiSession: SpawnSession = (task, signal) => {
  const opening = createPiSession(task, signal);
  return withAbort(opening, signal, "Subagent spawn aborted.").catch(
    (error) => {
      // SDK creation cannot be interrupted. Dispose a late session without starting it.
      void opening
        .then(
          (session) => session.dispose(),
          () => {},
        )
        .catch(() => {});
      throw error;
    },
  );
};
