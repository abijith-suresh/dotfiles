import type { SpawnTask, SubagentEvent, SubagentMeta } from "./domain.ts";

export interface SubagentSession {
  meta(): SubagentMeta;
  start(onEvent: (event: SubagentEvent) => void): void;
  interrupt(): Promise<void>;
  dispose(): Promise<void>;
}

export type SpawnSession = (
  task: SpawnTask,
  signal?: AbortSignal,
) => Promise<SubagentSession>;

/** Stop waiting on cancellation. The owner remains responsible for cleanup. */
export function withAbort<T>(
  work: Promise<T>,
  signal?: AbortSignal,
  message = "Operation was aborted.",
): Promise<T> {
  if (!signal) return work;
  return new Promise((resolve, reject) => {
    const abort = () => reject(new Error(message));
    if (signal.aborted) abort();
    else signal.addEventListener("abort", abort, { once: true });
    work
      .then(resolve, reject)
      .finally(() => signal.removeEventListener("abort", abort));
  });
}

export async function withDeadline<T>(
  work: Promise<T>,
  timeoutMs: number,
): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      work,
      new Promise<never>((_, reject) => {
        timer = setTimeout(
          () => reject(new Error("Deadline exceeded")),
          timeoutMs,
        );
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}
