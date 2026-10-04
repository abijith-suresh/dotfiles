import assert from "node:assert/strict";
import { mock, test } from "node:test";
import { createDeferredResultDelivery } from "../../configs/pi/.pi/agent/extensions/subagents/src/result-delivery.ts";

const children: any[] = [];
let creationGate: Promise<void> | undefined;
mock.module(
  "../../configs/pi/.pi/agent/extensions/subagents/src/pi-session.ts",
  {
    exports: {
      spawnPiSession: async (task: any, signal?: AbortSignal) => {
        await creationGate;
        const child = { task, closed: 0, emit: (_event: any) => {} };
        children.push(child);
        if (signal?.aborted) {
          child.closed++;
          signal.throwIfAborted();
        }
        return {
          meta: () => ({ backend: "pi", modelLabel: "test/model" }),
          start(listener: (event: any) => void) {
            child.emit = listener;
            if (task.prompt === "instant")
              child.emit({
                _tag: "RunSettled",
                outcome: { _tag: "Completed", finalText: "instant answer" },
              });
          },
          interrupt: async () => {
            if (task.prompt === "hang") await new Promise(() => {});
            else
              child.emit({
                _tag: "RunSettled",
                outcome: { _tag: "Interrupted", partialText: "partial" },
              });
          },
          dispose: async () => {
            child.closed++;
          },
        };
      },
    },
  },
);
const { default: subagents } =
  await import("../../configs/pi/.pi/agent/extensions/subagents/index.ts");
const tick = () => new Promise((resolve) => setImmediate(resolve));
async function until(predicate: () => boolean) {
  for (let i = 0; i < 200 && !predicate(); i++) await tick();
  assert(predicate(), "expected lifecycle transition");
}
async function fixture() {
  children.length = 0;
  const tools = new Map<string, any>();
  const hooks = new Map<string, any>();
  const commands = new Map<string, any>();
  const messages: any[] = [];
  const entries: any[] = [];
  let idle = false;
  const ctx = {
    cwd: process.cwd(),
    hasUI: false,
    modelRegistry: {},
    isIdle: () => idle,
    isProjectTrusted: () => false,
  };
  subagents({
    registerTool: (tool: any) => tools.set(tool.name, tool),
    on: (name: string, hook: any) => hooks.set(name, hook),
    registerCommand: (name: string, command: any) =>
      commands.set(name, command),
    registerMessageRenderer() {},
    registerEntryRenderer() {},
    appendEntry: (type: string, data: any) => entries.push({ type, data }),
    getThinkingLevel: () => "off",
    sendMessage: (message: any, options: any) =>
      messages.push({ ...message, options }),
  } as any);
  await hooks.get("session_start")({}, ctx);
  return {
    messages,
    entries,
    commands,
    btw: (prompt: string) =>
      commands.get("btw").handler(prompt, {
        ...ctx,
        mode: "tui",
        hasUI: true,
        ui: { notify() {} },
      }),
    call: (name: string, args: any, signal?: AbortSignal) =>
      tools.get(name).execute("test", args, signal, undefined, ctx),
    idle: async () => {
      idle = true;
      await hooks.get("agent_settled")({}, ctx);
    },
    shutdown: () => hooks.get("session_shutdown")({}, ctx),
  };
}
function complete(child: any, text = "answer") {
  child.emit({
    _tag: "RunSettled",
    outcome: { _tag: "Completed", finalText: text },
  });
}

test("background spawn returns before completion, settles once and releases the session", async () => {
  const f = await fixture();
  try {
    const spawned = await f.call("subagent_spawn", {
      name: "background",
      prompt: "task",
    });
    assert.equal(spawned.details.id, "sa-1");
    assert.equal(children[0].closed, 0);
    assert.equal(f.commands.has("subagents"), false);
    complete(children[0]);
    complete(children[0], "duplicate");
    await until(() => children[0].closed === 1);
    assert.equal(f.messages.length, 0);
    await f.idle();
    assert.equal(f.messages.length, 1);
    assert.match(f.messages[0].content, /answer/);
    assert.deepEqual(f.messages[0].options, {
      deliverAs: "followUp",
      triggerTurn: true,
    });
    await f.idle();
    assert.equal(f.messages.length, 1);
  } finally {
    await f.shutdown();
  }
  assert.equal(children[0].closed, 1);
});
test("late completion while parent idle triggers automatic delivery", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "late", prompt: "late" });
    await f.idle();
    complete(children[0], "late result");
    await until(() => f.messages.length === 1 && children[0].closed === 1);
    assert.match(f.messages[0].content, /late result/);
  } finally {
    await f.shutdown();
  }
});
test("foreground waits, handles instant completion and does not notify again", async () => {
  const f = await fixture();
  try {
    let returned = false;
    const pending = f
      .call("subagent_spawn", {
        name: "foreground",
        prompt: "work",
        mode: "foreground",
      })
      .then((r: any) => {
        returned = true;
        return r;
      });
    await until(() => children.length === 1);
    await tick();
    assert.equal(returned, false);
    complete(children[0], "foreground answer");
    assert.match((await pending).content[0].text, /foreground answer/);
    const instant = await f.call("subagent_spawn", {
      name: "instant",
      prompt: "instant",
      mode: "foreground",
    });
    assert.match(instant.content[0].text, /instant answer/);
    await f.idle();
    assert.equal(f.messages.length, 0);
  } finally {
    await f.shutdown();
  }
});
test("aborted wait restores auto delivery of already-settled and later children", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "one", prompt: "one" });
    await f.call("subagent_spawn", { name: "two", prompt: "two" });
    const controller = new AbortController();
    const waiting = f.call(
      "subagent_wait",
      { ids: ["sa-1", "sa-2"] },
      controller.signal,
    );
    const rejected = assert.rejects(waiting, /Wait aborted/);
    await tick();
    complete(children[0], "early answer");
    await until(() => children[0].closed === 1);
    controller.abort();
    await rejected;
    await f.idle();
    assert.equal(f.messages.length, 1);
    complete(children[1], "later answer");
    await until(() => f.messages.length === 2);
  } finally {
    await f.shutdown();
  }
});
test("explicit wait consumes queued completion and cancellation does not notify twice", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "wait", prompt: "wait" });
    complete(children[0]);
    await until(() => children[0].closed === 1);
    assert.match(
      (await f.call("subagent_wait", { ids: ["sa-1"] })).content[0].text,
      /answer/,
    );
    await f.call("subagent_spawn", { name: "cancel", prompt: "cancel" });
    const cancelled = await f.call("subagent_cancel", { ids: ["sa-2"] });
    assert.match(cancelled.content[0].text, /Cancelled/);
    await f.idle();
    assert.equal(f.messages.length, 0);
    await until(() => children.every((c) => c.closed === 1));
  } finally {
    await f.shutdown();
  }
});
test("errors deliver once; shutdown suppresses pending results and closes active children", async () => {
  const f = await fixture();
  await f.call("subagent_spawn", { name: "error", prompt: "error" });
  children[0].emit({
    _tag: "RunSettled",
    outcome: {
      _tag: "Failed",
      errorText: "offline failure",
      partialText: "partial",
    },
  });
  await until(() => children[0].closed === 1);
  await f.idle();
  assert.match(f.messages[0].content, /offline failure/);
  await f.call("subagent_spawn", { name: "running", prompt: "running" });
  await f.shutdown();
  complete(children[1], "too late");
  await tick();
  assert.equal(f.messages.length, 1);
  assert(children.every((c) => c.closed === 1));
});
test("duplicate tasks and concurrent reservations respect the four-agent cap", async () => {
  const f = await fixture();
  try {
    const first = f.call("subagent_spawn", { name: "one", prompt: "same" });
    const duplicate = f.call("subagent_spawn", {
      name: "duplicate",
      prompt: "same",
    });
    await assert.rejects(duplicate, /already running/);
    await first;
    const results = await Promise.allSettled(
      Array.from({ length: 4 }, (_, i) =>
        f.call("subagent_spawn", { name: `task${i}`, prompt: `task${i}` }),
      ),
    );
    assert.equal(results.filter((r) => r.status === "fulfilled").length, 3);
    assert.equal(children.length, 4);
  } finally {
    await f.shutdown();
  }
  assert(children.every((c) => c.closed === 1));
});
test("delivery holds survive cancellation and reject late duplicate settlement", () => {
  const delivery = createDeferredResultDelivery<{ id: string }>();
  const release = delivery.hold(["one"]);
  delivery.defer({ id: "one" });
  assert.deepEqual(delivery.drain(), []);
  release();
  release();
  assert.deepEqual(delivery.drain(), [{ id: "one" }]);
  delivery.defer({ id: "one" });
  assert.deepEqual(delivery.drain(), []);
});

test("shutdown discards a settled result still pending parent delivery", async () => {
  const f = await fixture();
  await f.call("subagent_spawn", { name: "pending", prompt: "pending" });
  complete(children[0]);
  await until(() => children[0].closed === 1);
  await f.shutdown();
  await f.idle();
  assert.equal(f.messages.length, 0);
});
test("cancel force-disposes a backend that never acknowledges interruption", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "hang", prompt: "hang" });
    await f.call("subagent_cancel", { ids: ["sa-1"] });
    await until(() => children[0].closed === 1);
    const status = await f.call("subagent_check", { id: "sa-1" });
    assert.match(status.content[0].text, /force-disposed/);
    await f.idle();
    assert.equal(f.messages.length, 0);
  } finally {
    await f.shutdown();
  }
});

test("status retains streaming text, turn counts, usage and final output", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "streaming", prompt: "streaming" });
    const child = children[0];
    child.emit({ _tag: "AssistantDelta", delta: "live preview" });
    child.emit({ _tag: "UsageChanged", tokens: 2048, contextWindow: 4096 });
    child.emit({
      _tag: "MetaChanged",
      meta: { modelLabel: "test/updated", sessionFilePath: "native-session" },
    });
    await tick();
    const live = await f.call("subagent_check", { id: "sa-1" });
    assert.match(live.content[0].text, /live preview/);
    assert.match(live.content[0].text, /test\/updated/);
    assert.match(live.content[0].text, /50%\/4.1k/);
    child.emit({ _tag: "AssistantMessage" });
    await tick();
    const between = await f.call("subagent_check", { id: "sa-1" });
    assert.equal(between.details.turns, 1);
    assert.doesNotMatch(between.content[0].text, /live preview/);
    complete(child, "finished answer");
    const result = await f.call("subagent_wait", { ids: ["sa-1", "sa-1"] });
    assert.equal(result.details.results.length, 1);
    assert.match(result.content[0].text, /finished answer/);
    await until(() => child.closed === 1);
  } finally {
    await f.shutdown();
  }
});

test("wait and cancel reject empty, unknown and private ids without touching children", async () => {
  const f = await fixture();
  try {
    await f.call("subagent_spawn", { name: "public", prompt: "public" });
    await f.btw("private side question");
    for (const tool of ["subagent_wait", "subagent_cancel"]) {
      await assert.rejects(f.call(tool, { ids: [] }), /at least one/);
      await assert.rejects(
        f.call(tool, { ids: ["unknown"] }),
        /Unknown.*Known: sa-1/,
      );
      await assert.rejects(
        f.call(tool, { ids: ["btw-1"] }),
        /Unknown.*Known: sa-1/,
      );
    }
    assert(children.every((child) => child.closed === 0));
    const listed = await f.call("subagent_list", {});
    assert.equal(listed.details.subagents.length, 1);
    complete(children[1], "private answer");
    await until(() => f.entries.length === 1);
    assert.equal(f.entries[0].type, "btw-result");
    assert.equal(f.entries[0].data.answer, "private answer");
    await f.idle();
    assert.equal(f.messages.length, 0);
  } finally {
    await f.shutdown();
  }
});

test("shutdown during SDK creation prevents a late child from starting", async () => {
  const f = await fixture();
  const gate = Promise.withResolvers<void>();
  creationGate = gate.promise;
  try {
    const pending = f.call("subagent_spawn", {
      name: "opening",
      prompt: "opening",
    });
    const rejected = assert.rejects(pending, /shutting down/);
    await tick();
    await f.shutdown();
    gate.resolve();
    await rejected;
    assert.equal(children[0].closed, 1);
    assert.equal(f.messages.length, 0);
  } finally {
    creationGate = undefined;
    gate.resolve();
  }
});
