import assert from "node:assert/strict";
import { test } from "node:test";
import askUser from "../extensions/ask-user/index.ts";

function fixture() {
  let tool: any;
  askUser({
    registerTool: (value: any) => {
      tool = value;
    },
  } as any);
  return tool;
}
const theme = { fg: (_: string, s: string) => s, bold: (s: string) => s };
const questions = [
  {
    id: "scope",
    question: "Which scope?",
    options: [{ label: "Local" }, { label: "Shared" }],
  },
  { id: "name", question: "What name?" },
];
function interact(
  tool: any,
  params: any,
  keys: string[],
  signal?: AbortSignal,
) {
  return tool.execute("test", params, signal, undefined, {
    hasUI: true,
    mode: "tui",
    ui: {
      custom: async (factory: any) => {
        let completed: any;
        const tui = {
          requestRender() {},
          terminal: { rows: 24, columns: 80 },
          getCursorPosition() {
            return { row: 0, col: 0 };
          },
        };
        const component = factory(tui, theme, {}, (value: any) => {
          completed = value;
        });
        for (const key of keys) {
          component.handleInput(key);
          for (const width of [1, 20, 80])
            assert(component.render(width).length > 0);
        }
        assert(completed, "dialog must finish through keyboard input");
        component.dispose();
        return completed;
      },
    },
  });
}
test("multiple questions, absent options, free text and consolidated submission", async () => {
  const result = await interact(fixture(), { questions }, [
    "2",
    "typed name",
    "\r",
    "\r",
  ]);
  assert.equal(result.details.status, "answered");
  assert.deepEqual(
    result.structuredContent.answers.map((a: any) => [
      a.id,
      a.answer,
      a.wasCustom,
    ]),
    [
      ["scope", "Shared", false],
      ["name", "typed name", true],
    ],
  );
});
test("review can revisit choices and edit a saved free-text answer", async () => {
  const result = await interact(fixture(), { questions }, [
    "1",
    "first",
    "\r",
    "\x1b[Z",
    "\x1b[Z",
    "2",
    "\x7f",
    "\x7f",
    "\x7f",
    "\x7f",
    "\x7f",
    "second",
    "\r",
    "\r",
  ]);
  assert.deepEqual(
    result.details.answers.map((a: any) => a.answer),
    ["Shared", "second"],
  );
});
test("dismissal discards partial answers", async () => {
  const result = await interact(fixture(), { questions }, [
    "1",
    "\x1b",
    "\x1b",
  ]);
  assert.equal(result.details.status, "dismissed");
  assert.deepEqual(result.details.answers, []);
});
test("abort during partial form returns no answers and finishes once", async () => {
  const controller = new AbortController();
  const tool = fixture();
  let completed = 0;
  const result = await tool.execute(
    "test",
    { questions },
    controller.signal,
    undefined,
    {
      hasUI: true,
      mode: "tui",
      ui: {
        custom: (factory: any) =>
          new Promise((resolve) => {
            const component = factory(
              { requestRender() {} },
              theme,
              {},
              (value: any) => {
                completed++;
                resolve(value);
              },
            );
            component.handleInput("1");
            controller.abort();
            component.handleInput("\x1b");
            component.dispose();
          }),
      },
    },
  );
  assert.equal(completed, 1);
  assert.deepEqual(result.structuredContent, {
    status: "cancelled",
    answers: [],
  });
});
test("headless cancellation takes priority and headless calls never open UI", async () => {
  const tool = fixture();
  const context = { hasUI: false, mode: "print" };
  const cancelled = await tool.execute(
    "test",
    { questions },
    AbortSignal.abort(),
    undefined,
    context,
  );
  assert.equal(cancelled.details.status, "cancelled");
  const unavailable = await tool.execute(
    "test",
    { questions },
    undefined,
    undefined,
    context,
  );
  assert.deepEqual(unavailable.structuredContent, {
    status: "unavailable",
    answers: [],
  });
});
test("RPC accepts free-text-only questions and discards cancelled partial replies", async () => {
  const tool = fixture();
  const controller = new AbortController();
  const result = await tool.execute(
    "test",
    { questions },
    controller.signal,
    undefined,
    {
      hasUI: true,
      mode: "rpc",
      ui: {
        select: async (_: string, labels: string[]) => labels[0],
        input: async () => {
          controller.abort();
          return "late";
        },
      },
    },
  );
  assert.deepEqual(result.details.answers, []);
  assert.equal(result.details.status, "cancelled");
  const freeText = await tool.execute(
    "test",
    { question: "Name?" },
    undefined,
    undefined,
    {
      hasUI: true,
      mode: "rpc",
      ui: { input: async () => "text" },
    },
  );
  assert.equal(freeText.details.answers[0].answer, "text");
});
test("legacy single-question choices and unique ids", async () => {
  const tool = fixture();
  const result = await interact(
    tool,
    { question: "Pick?", options: [{ label: "One" }, { label: "Two" }] },
    ["\x1b[B", "\r", "\r"],
  );
  assert.equal(result.details.answers[0].selectedIndex, 2);
  await assert.rejects(
    tool.execute(
      "test",
      { questions: [questions[0], questions[0]] },
      undefined,
      undefined,
      { hasUI: false },
    ),
    /unique/,
  );
});
