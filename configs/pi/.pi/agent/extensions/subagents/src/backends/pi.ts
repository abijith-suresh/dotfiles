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
import type { Cause } from "effect";
import { Effect, Queue, Stream } from "effect";
import type { SpawnSession, SubagentSession } from "../backend.ts";
import type { SubagentEvent, SubagentMeta } from "../domain.ts";
import { SpawnError } from "../domain.ts";
import { createToolCallTimeoutGuard } from "../tool-call-timeout.ts";

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

function waitBounded(operation: Promise<unknown>, timeoutMs: number) {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<void>((resolve) => {
    timer = setTimeout(resolve, timeoutMs);
  });
  return Promise.race([
    operation.then(
      () => undefined,
      () => undefined,
    ),
    timeout,
  ])
    .catch(() => {})
    .finally(() => {
      if (timer) clearTimeout(timer);
    });
}

/** Emit child session_shutdown (bounded), then dispose. Never throws. */
async function shutdownAndDisposeChildSession(session: AgentSession) {
  try {
    if (session.extensionRunner.hasHandlers("session_shutdown")) {
      await waitBounded(
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

export const spawnPiSession: SpawnSession = (task) =>
  Effect.gen(function* () {
    const registry = task.parent.modelRegistry;
    if (!registry) {
      return yield* new SpawnError({
        message: "pi backend requires the parent session's model registry.",
      });
    }

    const model = yield* Effect.try({
      try: () =>
        resolvePiModel(registry, task.model, task.parent.inheritedModel),
      catch: (error) => new SpawnError({ message: boundedError(error) }),
    });
    // pi's thinking levels ARE the shared reasoning-effort scale.
    const thinkingLevel = (task.reasoningEffort ??
      task.parent.inheritedThinkingLevel) as ThinkingLevel | undefined;

    const session = yield* Effect.tryPromise({
      try: async (signal) => {
        const { loader, settingsManager } = await createChildResources(
          task.cwd,
          task.parent.projectTrusted,
        );
        const { session } = await createAgentSession({
          cwd: task.cwd,
          sessionManager: SessionManager.create(task.cwd),
          settingsManager,
          resourceLoader: loader,
          model,
          thinkingLevel,
          excludeTools: [...CHILD_EXCLUDED_TOOL_NAMES],
        });
        // Start child extension session hooks/resources in headless mode.
        // A rejection here would otherwise leak the freshly created session:
        // the scope finalizer that owns cleanup is only registered later.
        try {
          await session.bindExtensions({ mode: "print" });
          if (signal.aborted) throw new Error("Subagent spawn aborted.");
        } catch (error) {
          await shutdownAndDisposeChildSession(session);
          throw error;
        }
        return session;
      },
      catch: (error) => new SpawnError({ message: boundedError(error) }),
    });

    const state = {
      closed: false,
      /** prompt() rejection for the active run; folded into RunSettled. */
      runError: undefined as string | undefined,
      /** One terminal event per run: lifecycle, prompt-rejection, and abort
       * fallbacks can all race to settle; the first wins. */
      settled: false,
    };

    const events = yield* Queue.make<SubagentEvent, Cause.Done>();
    const emit = (event: SubagentEvent) => {
      Queue.offerUnsafe(events, event);
    };

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
          emit({ _tag: "RunStarted" });
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
    const unsubscribe = session.subscribe(handleEvent);

    yield* Effect.addFinalizer(() =>
      Effect.promise(async () => {
        state.closed = true;
        unsubscribe();
        try {
          session.clearQueue();
        } catch {
          // Continue with abort/dispose.
        }
        await waitBounded(session.abort(), CHILD_SHUTDOWN_TIMEOUT_MS);
        await shutdownAndDisposeChildSession(session);
        Queue.endUnsafe(events);
      }),
    );

    /** Start the task without blocking spawn; errors become terminal events. */
    const startRun = (text: string) => {
      state.runError = undefined;
      state.settled = false;
      emit({ _tag: "RunStarted" });
      void session.prompt(text).catch((error) => {
        state.runError = boundedError(error);
        // Preflight failures may never start the agent lifecycle, so no
        // agent_settled will arrive for them.
        if (!session.isStreaming) settle();
      });
    };

    // Session naming is best-effort.
    yield* Effect.try(() =>
      session.sessionManager.appendSessionInfo(
        `${task.origin === "btw" ? "btw" : "subagent"}: ${task.title}`,
      ),
    ).pipe(Effect.ignore);

    emit({ _tag: "MetaChanged", meta: currentMeta() });
    startRun(task.prompt);

    return {
      meta: Effect.sync(currentMeta),
      events: Stream.fromQueue(events),
      interrupt: Effect.promise(async () => {
        if (state.closed) return;
        try {
          session.clearQueue();
        } catch {
          // Abort regardless.
        }
        await session.abort().catch(() => undefined);
        // Only resolve once streaming has actually stopped: reporting the
        // interrupt as complete while the run keeps working would let the
        // manager settle a run that is still mutating the workspace. The
        // manager bounds this effect at 5s and force-disposes on timeout.
        await session.waitForIdle();
        // No streaming run means no agent_settled will arrive; emit the
        // terminal event (once) so the run cannot look running forever.
        if (!state.closed && !state.settled) {
          state.settled = true;
          emit({ _tag: "RunSettled", outcome: { _tag: "Interrupted" } });
        }
      }),
    } satisfies SubagentSession;
  });
