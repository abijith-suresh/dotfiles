import assert from "node:assert/strict";
import { mock, test } from "node:test";
import { Effect, Exit, Scope, Stream } from "effect";
import * as sdk from "@earendil-works/pi-coding-agent";

let current: any;
let options: any;
let bindFailure = false;
let creationGate: Promise<void> | undefined;
mock.module("@earendil-works/pi-coding-agent", {
  exports: {
    ...sdk,
    DefaultResourceLoader: class {
      async reload() {}
    },
    SettingsManager: { create: () => ({}) },
    SessionManager: { create: () => ({}) },
    createAgentSession: async (value: any) => {
      options = value;
      await creationGate;
      const listeners = new Set<(event: any) => void>();
      current = {
        model: { provider: "test", id: "model", contextWindow: 4096 },
        messages: [],
        isStreaming: false,
        closed: 0,
        shutdowns: 0,
        sessionFile: "offline-session",
        sessionManager: { appendSessionInfo() {} },
        extensionRunner: {
          hasHandlers: () => true,
          emit: async () => {
            current.shutdowns++;
          },
        },
        bindExtensions: async () => {
          if (bindFailure) throw new Error("bind failed");
        },
        subscribe: (listener: any) => {
          listeners.add(listener);
          return () => listeners.delete(listener);
        },
        emit: (event: any) => {
          for (const listener of listeners) listener(event);
        },
        getContextUsage: () => undefined,
        getAllTools: () => [],
        prompt: async (text: string) => {
          if (text === "reject") throw new Error("preflight failed");
          current.isStreaming = true;
          current.emit({ type: "agent_start" });
        },
        clearQueue() {},
        abort: async () => {
          current.isStreaming = false;
        },
        waitForIdle: async () => {
          assert.equal(current.isStreaming, false);
        },
        dispose: () => {
          current.closed++;
        },
        listenerCount: () => listeners.size,
      };
      return { session: current };
    },
  },
});
const { piBackend } =
  await import("../extensions/subagents/src/backends/pi.ts");
const task = (prompt = "task") => ({
  prompt,
  title: "offline",
  cwd: process.cwd(),
  parent: {
    parentCwd: process.cwd(),
    projectTrusted: false,
    inheritedModel: { provider: "test", id: "model" },
    modelRegistry: { find: () => ({ provider: "test", id: "model" }) },
  },
});
async function spawn(prompt = "task") {
  const scope = await Effect.runPromise(Scope.make());
  const session = await Effect.runPromise(
    Scope.provide(piBackend.spawn(task(prompt) as any), scope),
  );
  return {
    session,
    scope,
    close: () => Effect.runPromise(Scope.close(scope, Exit.void)),
  };
}

test("native SDK child excludes delegation and ask_user; cancellation settles once and disposes", async () => {
  const f = await spawn();
  try {
    for (const name of [
      "subagent_spawn",
      "subagent_wait",
      "subagent_cancel",
      "subagent_check",
      "subagent_list",
      "ask_user",
    ])
      assert(options.excludeTools.includes(name));
    const terminal = Effect.runPromise(
      Stream.runCollect(
        f.session.events.pipe(
          Stream.filter((e) => e._tag === "RunSettled"),
          Stream.take(1),
        ),
      ),
    );
    await Effect.runPromise(f.session.interrupt);
    assert.equal((await terminal)[0].outcome._tag, "Interrupted");
    await Effect.runPromise(f.session.interrupt);
  } finally {
    await f.close();
  }
  assert.equal(current.closed, 1);
  assert.equal(current.shutdowns, 1);
  assert.equal(current.listenerCount(), 0);
});
test("prompt preflight rejection becomes a terminal error", async () => {
  const f = await spawn("reject");
  try {
    const events = await Effect.runPromise(
      Stream.runCollect(
        f.session.events.pipe(
          Stream.filter((e) => e._tag === "RunSettled"),
          Stream.take(1),
        ),
      ),
    );
    assert.equal(events[0].outcome._tag, "Failed");
    assert.match((events[0].outcome as any).errorText, /preflight failed/);
  } finally {
    await f.close();
  }
  assert.equal(current.closed, 1);
});
test("extension startup failure disposes the freshly-created SDK session", async () => {
  bindFailure = true;
  const scope = await Effect.runPromise(Scope.make());
  try {
    await assert.rejects(
      Effect.runPromise(Scope.provide(piBackend.spawn(task() as any), scope)),
      /bind failed/,
    );
    assert.equal(current.closed, 1);
  } finally {
    bindFailure = false;
    await Effect.runPromise(Scope.close(scope, Exit.void));
  }
});
test("aborted creation disposes a child that arrives after its tool was cancelled", async () => {
  const controller = new AbortController();
  const scope = await Effect.runPromise(Scope.make());
  const gate = Promise.withResolvers<void>();
  creationGate = gate.promise;
  try {
    const running = Effect.runPromise(
      Scope.provide(piBackend.spawn(task() as any), scope),
      { signal: controller.signal },
    );
    const rejected = assert.rejects(running);
    await new Promise((resolve) => setImmediate(resolve));
    controller.abort();
    await rejected;
    gate.resolve();
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(current.closed, 1);
  } finally {
    creationGate = undefined;
    gate.resolve();
    await Effect.runPromise(Scope.close(scope, Exit.void));
  }
});
