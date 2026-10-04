import assert from "node:assert/strict";
import { mock, test } from "node:test";
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
const { spawnPiSession } =
  await import("../../configs/pi/.pi/agent/extensions/subagents/src/pi-session.ts");
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
  const session = await spawnPiSession(task(prompt) as any);
  const events: any[] = [];
  const terminal = Promise.withResolvers<any>();
  session.start((event) => {
    events.push(event);
    if (event._tag === "RunSettled") terminal.resolve(event);
  });
  return {
    session,
    events,
    terminal: terminal.promise,
    close: () => session.dispose(),
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
    await f.session.interrupt();
    assert.equal((await f.terminal).outcome._tag, "Interrupted");
    await f.session.interrupt();
    assert.equal(
      f.events.filter((event) => event._tag === "RunSettled").length,
      1,
    );
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
    const event = await f.terminal;
    assert.equal(event.outcome._tag, "Failed");
    assert.match(event.outcome.errorText, /preflight failed/);
  } finally {
    await f.close();
  }
  assert.equal(current.closed, 1);
});
test("extension startup failure disposes the freshly-created SDK session", async () => {
  bindFailure = true;
  try {
    await assert.rejects(spawnPiSession(task() as any), /bind failed/);
    assert.equal(current.closed, 1);
  } finally {
    bindFailure = false;
  }
});
test("aborted creation disposes a child that arrives after its tool was cancelled", async () => {
  const controller = new AbortController();
  const gate = Promise.withResolvers<void>();
  creationGate = gate.promise;
  try {
    const running = spawnPiSession(task() as any, controller.signal);
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
  }
});

test("native events retain status and final output without copying the SDK transcript", async () => {
  const f = await spawn();
  try {
    current.getContextUsage = () => ({ tokens: 2048, contextWindow: 4096 });
    const message = {
      role: "assistant",
      provider: "test",
      model: "model",
      stopReason: "stop",
      content: [
        { type: "thinking", thinking: "private thinking" },
        {
          type: "toolCall",
          id: "tool-1",
          name: "read",
          arguments: { path: "file" },
        },
        { type: "text", text: "native answer" },
      ],
    };
    current.messages.push(message);
    for (const event of [
      { type: "message_end", message: { role: "user", content: "task" } },
      {
        type: "message_update",
        assistantMessageEvent: {
          type: "thinking_delta",
          delta: "private thinking",
        },
      },
      {
        type: "tool_execution_start",
        toolCallId: "tool-1",
        toolName: "read",
        args: { path: "file" },
      },
      {
        type: "tool_execution_update",
        toolCallId: "tool-1",
        partialResult: { content: [{ type: "text", text: "tool preview" }] },
      },
      {
        type: "tool_execution_end",
        toolCallId: "tool-1",
        toolName: "read",
        result: "tool result",
        isError: false,
      },
      { type: "queue_update", steering: ["queued steering"], followUp: [] },
      {
        type: "message_update",
        assistantMessageEvent: { type: "text_delta", delta: "live text" },
      },
      { type: "message_end", message },
      { type: "agent_settled" },
    ])
      current.emit(event);
    current.isStreaming = false;
    await f.terminal;
    const events = f.events;
    assert.deepEqual(
      events.filter((event) => event._tag !== "MetaChanged"),
      [
        { _tag: "AssistantDelta", delta: "live text" },
        { _tag: "AssistantMessage" },
        { _tag: "UsageChanged", tokens: 2048, contextWindow: 4096 },
        {
          _tag: "RunSettled",
          outcome: { _tag: "Completed", finalText: "native answer" },
        },
      ],
    );
    assert.equal(f.session.meta().sessionFilePath, "offline-session");
    assert.equal(current.messages[0], message);
  } finally {
    await f.close();
  }
  assert.equal(current.closed, 1);
});
