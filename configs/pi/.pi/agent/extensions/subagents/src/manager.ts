import {
  Context,
  Effect,
  Exit,
  Fiber,
  Layer,
  Result,
  Scope,
  Stream,
} from "effect";
import { SubagentSpawner, type SubagentSession } from "./backend.ts";
import type {
  RunOutcome,
  SpawnTask,
  SubagentEvent,
  SubagentSnapshot,
  SubagentStatus,
} from "./domain.ts";
import { ConcurrencyLimitError, SpawnError } from "./domain.ts";

export const MAX_RUNNING = 4;
export const MAX_TRACKED = 64;
const STOP_TIMEOUT_MS = 5_000;
const ERROR_TEXT_MAX_LENGTH = 4_096;
const LIVE_ASSISTANT_MAX_LENGTH = 128 * 1_024;
const FINAL_TEXT_MAX_LENGTH = 1_024 * 1_024;

function bounded(text: string) {
  return text.slice(0, ERROR_TEXT_MAX_LENGTH);
}

type MutableSnapshot = {
  -readonly [K in keyof SubagentSnapshot]: SubagentSnapshot[K];
};

interface Entry {
  snapshot: MutableSnapshot;
  session: SubagentSession;
  scope: Scope.Closeable;
  model?: string;
  reasoningEffort?: string;
}

// --- Read model ----------------------------------------------------------------

/** Synchronous snapshots for tool results. Snapshots are live objects; do not mutate. */
export interface SubagentReadModel {
  list(): ReadonlyArray<SubagentSnapshot>;
  get(id: string): SubagentSnapshot | undefined;
  setOnSettled(hook: ((snap: SubagentSnapshot) => void) | undefined): void;
}

// --- Service --------------------------------------------------------------------

export interface CancelResult {
  readonly id: string;
  readonly title: string;
  readonly status: SubagentStatus;
  readonly cancelled: boolean;
}

export interface SubagentManagerShape {
  spawn(
    task: SpawnTask,
  ): Effect.Effect<SubagentSnapshot, SpawnError | ConcurrencyLimitError>;
  /**
   * Wait until all listed subagents are settled. Unknown ids are treated as
   * settled (the tool layer validates ids first). Interest prevents pruning
   * until collection completes. Interruption leaves the children running.
   */
  waitFor(
    ids: ReadonlyArray<string>,
    onPending?: (pending: string[]) => void,
  ): Effect.Effect<void>;
  /** Cancel running subagents; resolves when they have settled. */
  cancel(
    ids: ReadonlyArray<string>,
  ): Effect.Effect<ReadonlyArray<CancelResult>>;
  readonly view: SubagentReadModel;
}

export class SubagentManager extends Context.Service<
  SubagentManager,
  SubagentManagerShape
>()("subagents/SubagentManager") {}

// --- Implementation --------------------------------------------------------------

const makeManager = Effect.gen(function* () {
  const spawnSession = yield* SubagentSpawner;
  // Detached forker for settlement cleanup and pruning that
  // preserves the manager's services instead of using the global runtime.
  const runDetached = Effect.runForkWith(yield* Effect.context());

  const entries = new Map<string, Entry>();
  const waitInterest = new Map<string, number>();
  /** One-shot nextChange waiters, swapped out before invocation so waiters
   * re-registering during notification are not visited in the same sweep. */
  let changeWaiters: Array<() => void> = [];
  const cleanups = new Set<Fiber.Fiber<unknown>>();
  let modelCounter = 0;
  let btwCounter = 0;
  let reserved = 0;
  const spawningTasks = new Set<string>();
  let disposed = false;
  let onSettled: ((snap: SubagentSnapshot) => void) | undefined;

  const notify = () => {
    const waiters = changeWaiters;
    changeWaiters = [];
    for (const waiter of waiters) waiter();
  };

  /** Resolves on the next state change. Interruption unregisters the waiter. */
  const nextChange = Effect.callback<void>((resume) => {
    const waiter = () => resume(Effect.void);
    changeWaiters.push(waiter);
    return Effect.sync(() => {
      const index = changeWaiters.indexOf(waiter);
      if (index >= 0) changeWaiters.splice(index, 1);
    });
  });

  const runningCount = () =>
    [...entries.values()].filter((e) => e.snapshot.status === "running").length;

  const addInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) waitInterest.set(id, (waitInterest.get(id) ?? 0) + 1);
  };
  const releaseInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) {
      const count = (waitInterest.get(id) ?? 1) - 1;
      if (count <= 0) waitInterest.delete(id);
      else waitInterest.set(id, count);
    }
  };

  const closeEntryScope = (entry: Entry) =>
    Scope.close(entry.scope, Exit.void).pipe(Effect.ignore);

  const pruneSettled = () => {
    if (entries.size <= MAX_TRACKED) return;
    const candidates = [...entries.values()]
      .filter(
        (e) =>
          e.snapshot.status !== "running" && !waitInterest.has(e.snapshot.id),
      )
      .sort(
        (a, b) =>
          (a.snapshot.settledAt ?? a.snapshot.createdAt) -
          (b.snapshot.settledAt ?? b.snapshot.createdAt),
      );
    for (const entry of candidates) {
      if (entries.size <= MAX_TRACKED) break;
      entries.delete(entry.snapshot.id);
      const fiber = runDetached(closeEntryScope(entry));
      cleanups.add(fiber);
      fiber.addObserver(() => cleanups.delete(fiber));
    }
  };

  const settle = (entry: Entry, outcome: RunOutcome) => {
    const s = entry.snapshot;
    if (s.status !== "running") return;
    s.settledAt = Date.now();
    switch (outcome._tag) {
      case "Completed":
        s.status = "done";
        s.errorText = undefined;
        s.finalText = outcome.finalText.slice(0, FINAL_TEXT_MAX_LENGTH);
        break;
      case "Failed":
        s.status = "error";
        s.errorText = bounded(outcome.errorText);
        // Never let a failed run report the previous run's successful output.
        s.finalText = (outcome.partialText ?? "").slice(
          0,
          FINAL_TEXT_MAX_LENGTH,
        );
        break;
      case "Interrupted":
        s.status = "error";
        s.errorText = "Run was aborted";
        s.finalText = (outcome.partialText ?? "").slice(
          0,
          FINAL_TEXT_MAX_LENGTH,
        );
        break;
    }
    s.liveText = undefined;
    notify();
    try {
      // During teardown, don't queue results into a shutting-down session.
      if (!disposed) onSettled?.(s);
    } catch {
      // The parent session may be unavailable; settlement stays final.
    }
    // Tasks are one-shot. Release the SDK session as soon as it settles.
    const cleanup = runDetached(
      closeEntryScope(entry).pipe(
        Effect.timeout(STOP_TIMEOUT_MS),
        Effect.ignore,
      ),
    );
    cleanups.add(cleanup);
    cleanup.addObserver(() => cleanups.delete(cleanup));
    pruneSettled();
  };

  const foldEvent = (entry: Entry, event: SubagentEvent) => {
    const s = entry.snapshot;
    // A one-shot task cannot restart from a late backend event.
    if (s.status !== "running") return;
    switch (event._tag) {
      case "RunStarted":
        s.status = "running";
        s.settledAt = undefined;
        s.errorText = undefined;
        break;
      case "RunSettled":
        settle(entry, event.outcome);
        return; // settle() already notified
      case "AssistantDelta":
        s.liveText = ((s.liveText ?? "") + event.delta).slice(
          -LIVE_ASSISTANT_MAX_LENGTH,
        );
        break;
      case "AssistantMessage":
        s.liveText = undefined;
        s.turns++;
        break;
      case "UsageChanged":
        s.usage = {
          tokens: event.tokens ?? s.usage.tokens,
          contextWindow: event.contextWindow ?? s.usage.contextWindow,
        };
        break;
      case "MetaChanged":
        s.meta = { ...s.meta, ...event.meta };
        break;
    }
    notify();
  };

  const spawn = (task: SpawnTask) =>
    Effect.gen(function* () {
      const taskKey = JSON.stringify([
        task.origin ?? "model",
        task.cwd,
        task.prompt.trim(),
        task.model,
        task.reasoningEffort,
      ]);
      // Reserve synchronously (before the first yield inside doSpawn) so
      // parallel tool calls cannot race past the global cap.
      yield* Effect.suspend(
        (): Effect.Effect<void, SpawnError | ConcurrencyLimitError> => {
          if (disposed) {
            return new SpawnError({
              message: "Subagent manager is shutting down.",
            });
          }
          if (
            spawningTasks.has(taskKey) ||
            [...entries.values()].some(
              (entry) =>
                entry.snapshot.status === "running" &&
                JSON.stringify([
                  entry.snapshot.origin,
                  entry.snapshot.cwd,
                  entry.snapshot.prompt.trim(),
                  entry.model,
                  entry.reasoningEffort,
                ]) === taskKey,
            )
          ) {
            return new SpawnError({
              message:
                "This task is already running. Use its existing subagent id.",
            });
          }
          if (runningCount() + reserved >= MAX_RUNNING) {
            return new ConcurrencyLimitError({
              message: `Max ${MAX_RUNNING} subagents can run concurrently. Wait for one to finish before spawning another.`,
            });
          }
          reserved++;
          spawningTasks.add(taskKey);
          return Effect.void;
        },
      );

      const doSpawn = Effect.gen(function* () {
        const scope = yield* Scope.make();
        const session = yield* Scope.provide(spawnSession(task), scope).pipe(
          Effect.onError(() => Scope.close(scope, Exit.void)),
        );
        if (disposed) {
          yield* Scope.close(scope, Exit.void);
          return yield* new SpawnError({
            message: "Subagent manager shut down while spawning.",
          });
        }

        const origin = task.origin ?? "model";
        const id =
          origin === "btw" ? `btw-${++btwCounter}` : `sa-${++modelCounter}`;
        const meta = yield* session.meta;
        const entry: Entry = {
          snapshot: {
            id,
            origin,
            backend: "pi",
            title: task.title,
            prompt: task.prompt,
            cwd: task.cwd,
            status: "running",
            createdAt: Date.now(),
            meta,
            usage: { contextWindow: meta.contextWindow },
            finalText: "",
            turns: 0,
          },
          session,
          scope,
          model: task.model,
          reasoningEffort: task.reasoningEffort,
        };
        entries.set(id, entry);

        // Pump: fold the event stream into the snapshot. Tied to the entry
        // scope, so closing the scope stops it. If the stream ends while the
        // subagent still looks running, the backend died out from under us.
        const pump = Stream.runForEach(session.events, (event) =>
          Effect.sync(() => foldEvent(entry, event)),
        ).pipe(
          Effect.ensuring(
            Effect.sync(() => {
              if (entry.snapshot.status === "running") {
                settle(entry, {
                  _tag: "Failed",
                  errorText: "Backend event stream ended unexpectedly",
                });
              }
            }),
          ),
        );
        yield* Scope.provide(Effect.forkScoped(pump), scope);

        notify();
        return entry.snapshot as SubagentSnapshot;
      });

      return yield* doSpawn.pipe(
        Effect.ensuring(
          Effect.sync(() => {
            reserved--;
            spawningTasks.delete(taskKey);
            notify();
          }),
        ),
      );
    });

  const waitFor = (
    ids: ReadonlyArray<string>,
    onPending?: (pending: string[]) => void,
  ) =>
    Effect.suspend(() => {
      const unique = [...new Set(ids)];
      addInterest(unique);
      const loop = Effect.gen(function* () {
        while (true) {
          const pending = unique.filter(
            (id) => entries.get(id)?.snapshot.status === "running",
          );
          if (pending.length === 0) return;
          onPending?.(pending);
          yield* nextChange;
        }
      });
      return loop.pipe(
        Effect.ensuring(
          Effect.sync(() => {
            releaseInterest(unique);
            pruneSettled();
          }),
        ),
      );
    });

  /** Interrupt one running entry, force-closing its scope after 5s. */
  const abortEntry = (entry: Entry) =>
    Effect.gen(function* () {
      if (entry.snapshot.status !== "running") return;
      const graceful = yield* entry.session.interrupt.pipe(
        Effect.timeout(STOP_TIMEOUT_MS),
        Effect.result,
      );
      if (Result.isFailure(graceful)) {
        // Settle before closing the scope so the pump's stream-ended
        // fallback ("Backend event stream ended unexpectedly") cannot win
        // the race and report the wrong terminal reason.
        yield* Effect.sync(() => {
          settle(entry, {
            _tag: "Failed",
            errorText: "Abort deadline exceeded; session was force-disposed",
          });
          notify();
        });
        // Bound the close like disposeAll does: a stuck backend finalizer
        // must not hang cancel after the run is already settled.
        yield* closeEntryScope(entry).pipe(
          Effect.timeout(STOP_TIMEOUT_MS),
          Effect.ignore,
        );
      }
    });

  const cancel = (ids: ReadonlyArray<string>) =>
    Effect.suspend(() => {
      const unique = [...new Set(ids)];
      const running = unique
        .map((id) => entries.get(id))
        .filter(
          (entry): entry is Entry => entry?.snapshot.status === "running",
        );
      const runningIds = running.map((entry) => entry.snapshot.id);
      // Keep running entries tracked while interruption completes.
      addInterest(runningIds);
      const work = Effect.gen(function* () {
        yield* Effect.forEach(running, abortEntry, {
          concurrency: "unbounded",
        });
        while (running.some((entry) => entry.snapshot.status === "running")) {
          yield* nextChange;
        }
      });
      return work.pipe(
        Effect.ensuring(
          Effect.sync(() => {
            releaseInterest(runningIds);
            pruneSettled();
          }),
        ),
        Effect.map((): ReadonlyArray<CancelResult> =>
          unique.map((id) => {
            const snapshot = entries.get(id)?.snapshot;
            return {
              id,
              title: snapshot?.title ?? "?",
              status: snapshot?.status ?? "error",
              cancelled: runningIds.includes(id),
            };
          }),
        ),
      );
    });

  const disposeAll = Effect.gen(function* () {
    disposed = true;
    const all = [...entries.values()];
    entries.clear();
    yield* Effect.forEach(
      all,
      (entry) =>
        closeEntryScope(entry).pipe(
          Effect.timeout(STOP_TIMEOUT_MS),
          Effect.ignore,
        ),
      { concurrency: "unbounded" },
    );
    // Pruning cleanups are detached; bound them like everything else so a
    // stuck backend finalizer cannot block runtime shutdown indefinitely.
    yield* Effect.forEach(
      [...cleanups],
      (fiber) =>
        Fiber.await(fiber).pipe(Effect.timeout(STOP_TIMEOUT_MS), Effect.ignore),
      { concurrency: "unbounded" },
    ).pipe(Effect.ignore);
    yield* Effect.sync(() => notify());
  });

  const view: SubagentReadModel = {
    list: () => [...entries.values()].map((entry) => entry.snapshot),
    get: (id) => entries.get(id)?.snapshot,
    setOnSettled: (hook) => {
      onSettled = hook;
    },
  };

  // Safety net: disposing the ManagedRuntime tears everything down even if
  // the extension forgot to call disposeAll explicitly.
  yield* Effect.addFinalizer(() => disposeAll);

  return SubagentManager.of({
    spawn,
    waitFor,
    cancel,
    view,
  });
});

export const SubagentManagerLive: Layer.Layer<
  SubagentManager,
  never,
  SubagentSpawner
> = Layer.effect(SubagentManager, makeManager);
