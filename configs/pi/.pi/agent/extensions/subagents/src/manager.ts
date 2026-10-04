import {
  withAbort,
  withDeadline,
  type SpawnSession,
  type SubagentSession,
} from "./backend.ts";
import type {
  RunOutcome,
  SpawnTask,
  SubagentEvent,
  SubagentSnapshot,
  SubagentStatus,
} from "./domain.ts";
import { spawnPiSession } from "./pi-session.ts";

export const MAX_RUNNING = 4;
export const MAX_TRACKED = 64;
const STOP_TIMEOUT_MS = 5_000;
const ERROR_TEXT_MAX_LENGTH = 4_096;
const LIVE_TEXT_MAX_LENGTH = 128 * 1_024;
const FINAL_TEXT_MAX_LENGTH = 1_024 * 1_024;

type MutableSnapshot = {
  -readonly [K in keyof SubagentSnapshot]: SubagentSnapshot[K];
};
interface Entry {
  snapshot: MutableSnapshot;
  session?: SubagentSession;
  taskKey: string;
  cleanup?: Promise<void>;
}
export interface CancelResult {
  readonly id: string;
  readonly title: string;
  readonly status: SubagentStatus;
  readonly cancelled: boolean;
}

export function createSubagentManager(
  spawnSession: SpawnSession = spawnPiSession,
) {
  const shutdown = new AbortController();
  const entries = new Map<string, Entry>();
  const pendingSpawns = new Set<string>();
  const waitInterest = new Map<string, number>();
  const changes = new Set<() => void>();
  const cleanups = new Set<Promise<void>>();
  let modelCounter = 0;
  let btwCounter = 0;
  let disposed = false;
  let onSettled: ((snap: SubagentSnapshot) => void) | undefined;

  const notify = () => {
    for (const listener of [...changes]) listener();
  };
  const addInterest = (ids: readonly string[]) => {
    for (const id of ids) waitInterest.set(id, (waitInterest.get(id) ?? 0) + 1);
  };
  const releaseInterest = (ids: readonly string[]) => {
    for (const id of ids) {
      const count = (waitInterest.get(id) ?? 1) - 1;
      if (count <= 0) waitInterest.delete(id);
      else waitInterest.set(id, count);
    }
    pruneSettled();
  };
  const pruneSettled = () => {
    if (entries.size <= MAX_TRACKED) return;
    const candidates = [...entries.values()]
      .filter(
        (entry) =>
          entry.snapshot.status !== "running" &&
          !waitInterest.has(entry.snapshot.id),
      )
      .sort(
        (a, b) =>
          (a.snapshot.settledAt ?? a.snapshot.createdAt) -
          (b.snapshot.settledAt ?? b.snapshot.createdAt),
      );
    for (const entry of candidates) {
      if (entries.size <= MAX_TRACKED) break;
      entries.delete(entry.snapshot.id);
    }
  };
  const closeEntry = (entry: Entry) => {
    if (!entry.cleanup) {
      // Tracked results must not retain the disposed SDK session and its transcript.
      const session = entry.session;
      entry.session = undefined;
      entry.cleanup = withDeadline(
        Promise.resolve().then(() => session?.dispose()),
        STOP_TIMEOUT_MS,
      ).catch(() => {});
      cleanups.add(entry.cleanup);
      void entry.cleanup.finally(() => cleanups.delete(entry.cleanup!));
    }
    return entry.cleanup;
  };
  const settle = (entry: Entry, outcome: RunOutcome) => {
    const snap = entry.snapshot;
    if (snap.status !== "running") return;
    snap.settledAt = Date.now();
    snap.status = outcome._tag === "Completed" ? "done" : "error";
    snap.errorText =
      outcome._tag === "Failed"
        ? outcome.errorText.slice(0, ERROR_TEXT_MAX_LENGTH)
        : outcome._tag === "Interrupted"
          ? "Run was aborted"
          : undefined;
    snap.finalText = (
      outcome._tag === "Completed"
        ? outcome.finalText
        : (outcome.partialText ?? "")
    ).slice(0, FINAL_TEXT_MAX_LENGTH);
    snap.liveText = undefined;
    notify();
    try {
      if (!disposed) onSettled?.(snap);
    } catch {
      // A disappearing parent must not prevent child cleanup.
    }
    closeEntry(entry);
    pruneSettled();
  };
  const foldEvent = (entry: Entry, event: SubagentEvent) => {
    const snap = entry.snapshot;
    if (snap.status !== "running") return;
    switch (event._tag) {
      case "RunSettled":
        settle(entry, event.outcome);
        return;
      case "AssistantDelta":
        snap.liveText = ((snap.liveText ?? "") + event.delta).slice(
          -LIVE_TEXT_MAX_LENGTH,
        );
        break;
      case "AssistantMessage":
        snap.liveText = undefined;
        snap.turns++;
        break;
      case "UsageChanged":
        snap.usage = {
          tokens: event.tokens ?? snap.usage.tokens,
          contextWindow: event.contextWindow ?? snap.usage.contextWindow,
        };
        break;
      case "MetaChanged":
        snap.meta = { ...snap.meta, ...event.meta };
        break;
    }
  };

  const spawn = async (
    task: SpawnTask,
    signal?: AbortSignal,
  ): Promise<SubagentSnapshot> => {
    signal = signal
      ? AbortSignal.any([signal, shutdown.signal])
      : shutdown.signal;
    signal.throwIfAborted();
    if (disposed) throw new Error("Subagent manager is shutting down.");
    const taskKey = JSON.stringify([
      task.origin ?? "model",
      task.cwd,
      task.prompt.trim(),
      task.model,
      task.reasoningEffort,
    ]);
    if (
      pendingSpawns.has(taskKey) ||
      [...entries.values()].some(
        (entry) =>
          entry.snapshot.status === "running" && entry.taskKey === taskKey,
      )
    ) {
      throw new Error(
        "This task is already running. Use its existing subagent id.",
      );
    }
    const running = [...entries.values()].filter(
      (entry) => entry.snapshot.status === "running",
    ).length;
    if (running + pendingSpawns.size >= MAX_RUNNING) {
      throw new Error(
        `Max ${MAX_RUNNING} subagents can run concurrently. Wait for one to finish before spawning another.`,
      );
    }
    // Reserve before the first await, including tasks whose SDK session is still opening.
    pendingSpawns.add(taskKey);
    let session: SubagentSession | undefined;
    let entry: Entry | undefined;
    try {
      session = await spawnSession(task, signal);
      if (disposed || signal?.aborted)
        throw new Error("Subagent spawn aborted or manager shut down.");
      const origin = task.origin ?? "model";
      const id =
        origin === "btw" ? `btw-${++btwCounter}` : `sa-${++modelCounter}`;
      const meta = session.meta();
      entry = {
        taskKey,
        session,
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
      };
      entries.set(id, entry);
      const active = entry;
      session.start((event) => foldEvent(active, event));
      return entry.snapshot;
    } catch (error) {
      if (entry) {
        entries.delete(entry.snapshot.id);
        await closeEntry(entry);
      } else if (session) {
        await withDeadline(session.dispose(), STOP_TIMEOUT_MS).catch(() => {});
      }
      throw error;
    } finally {
      pendingSpawns.delete(taskKey);
    }
  };

  const waitFor = async (
    ids: readonly string[],
    onPending?: (pending: string[]) => void,
    signal?: AbortSignal,
  ) => {
    const unique = [...new Set(ids)];
    addInterest(unique);
    let check: (() => void) | undefined;
    let abort: (() => void) | undefined;
    try {
      await new Promise<void>((resolve, reject) => {
        abort = () =>
          reject(new Error("Wait aborted. Subagents keep running."));
        check = () => {
          const pending = unique.filter(
            (id) => entries.get(id)?.snapshot.status === "running",
          );
          if (pending.length === 0) resolve();
          else {
            try {
              onPending?.(pending);
            } catch (error) {
              reject(error);
            }
          }
        };
        changes.add(check);
        if (signal?.aborted) abort();
        else {
          signal?.addEventListener("abort", abort, { once: true });
          check();
        }
      });
    } finally {
      if (check) changes.delete(check);
      if (abort) signal?.removeEventListener("abort", abort);
      releaseInterest(unique);
    }
  };
  const abortEntry = async (entry: Entry) => {
    const session = entry.session;
    if (entry.snapshot.status !== "running" || !session) return;
    try {
      await withDeadline(
        Promise.resolve().then(() => session.interrupt()),
        STOP_TIMEOUT_MS,
      );
    } catch {
      settle(entry, {
        _tag: "Failed",
        errorText: "Abort deadline exceeded; session was force-disposed",
      });
      await closeEntry(entry);
    }
  };
  const cancel = async (
    ids: readonly string[],
    signal?: AbortSignal,
  ): Promise<readonly CancelResult[]> => {
    signal?.throwIfAborted();
    const unique = [...new Set(ids)];
    const running = unique
      .map((id) => entries.get(id))
      .filter((entry): entry is Entry => entry?.snapshot.status === "running");
    const runningIds = running.map((entry) => entry.snapshot.id);
    addInterest(unique);
    try {
      await withAbort(
        Promise.all(running.map(abortEntry)),
        signal,
        "Subagent cancellation aborted.",
      );
      await waitFor(runningIds, undefined, signal);
      return unique.map((id) => {
        const snapshot = entries.get(id)?.snapshot;
        return {
          id,
          title: snapshot?.title ?? "?",
          status: snapshot?.status ?? "error",
          cancelled: runningIds.includes(id),
        };
      });
    } finally {
      releaseInterest(unique);
    }
  };
  const dispose = async () => {
    disposed = true;
    shutdown.abort(new Error("Subagent manager is shutting down."));
    const all = [...entries.values()];
    entries.clear();
    notify();
    await Promise.all([...all.map(closeEntry), ...cleanups]);
  };
  const view = {
    list: (): readonly SubagentSnapshot[] =>
      [...entries.values()].map((entry) => entry.snapshot),
    get: (id: string): SubagentSnapshot | undefined =>
      entries.get(id)?.snapshot,
    setOnSettled: (hook: typeof onSettled) => {
      onSettled = hook;
    },
  };
  return { spawn, waitFor, cancel, dispose, view };
}
export type SubagentManager = ReturnType<typeof createSubagentManager>;
