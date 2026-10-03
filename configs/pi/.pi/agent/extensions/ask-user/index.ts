import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  Editor,
  Key,
  matchesKey,
  Text,
  truncateToWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";
import {
  ASK_USER_PROMPT_GUIDELINES,
  ASK_USER_PROMPT_SNIPPET,
  ASK_USER_TOOL_DESCRIPTION,
} from "./prompt.ts";

const Option = Type.Object({
  label: Type.String({ minLength: 1 }),
  description: Type.Optional(Type.String()),
});
const Question = Type.Object({
  id: Type.String({ minLength: 1, description: "Unique answer key" }),
  question: Type.String({ minLength: 1 }),
  options: Type.Optional(Type.Array(Option, { minItems: 2, maxItems: 5 })),
});
// Keep the old single-question arguments usable by existing callers.
const Params = Type.Union([
  Type.Object({
    questions: Type.Array(Question, { minItems: 1, maxItems: 8 }),
  }),
  Type.Object({
    question: Type.String({ minLength: 1 }),
    options: Type.Optional(Type.Array(Option, { minItems: 2, maxItems: 5 })),
  }),
]);
type QuestionInput = Static<typeof Question>;
type Answer = {
  id: string;
  question: string;
  answer: string;
  wasCustom: boolean;
  selectedIndex?: number;
};
type Outcome =
  | { status: "answered"; answers: Answer[] }
  | { status: "cancelled" | "dismissed" | "unavailable"; answers: [] };
const FREE_TEXT = "Write my own answer";

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description: ASK_USER_TOOL_DESCRIPTION,
    promptSnippet: ASK_USER_PROMPT_SNIPPET,
    promptGuidelines: ASK_USER_PROMPT_GUIDELINES,
    parameters: Params,
    outputSchema: Type.Object({
      status: Type.Union([
        Type.Literal("answered"),
        Type.Literal("cancelled"),
        Type.Literal("dismissed"),
        Type.Literal("unavailable"),
      ]),
      answers: Type.Array(
        Type.Object({
          id: Type.String(),
          question: Type.String(),
          answer: Type.String(),
          wasCustom: Type.Boolean(),
          selectedIndex: Type.Optional(Type.Number()),
        }),
      ),
    }),
    executionMode: "sequential",
    async execute(_id, params, signal, _update, ctx) {
      const questions: QuestionInput[] =
        "questions" in params
          ? params.questions
          : [
              {
                id: "answer",
                question: params.question,
                options: params.options,
              },
            ];
      if (new Set(questions.map((q) => q.id)).size !== questions.length)
        throw new Error("Question ids must be unique.");

      const pack = (outcome: Outcome) => ({
        content: [
          {
            type: "text" as const,
            text:
              outcome.status === "answered"
                ? JSON.stringify(outcome)
                : `ask_user ${outcome.status}. No answers submitted; do not assume answers.`,
          },
        ],
        details: { ...outcome, questions },
        structuredContent: outcome,
      });
      if (signal?.aborted) return pack({ status: "cancelled", answers: [] });
      if (!ctx.hasUI) return pack({ status: "unavailable", answers: [] });

      // RPC has native select/input dialogs but no custom component.
      if (ctx.mode === "rpc") {
        const answers: Answer[] = [];
        for (const q of questions) {
          const options = q.options ?? [];
          const labels = [
            ...options.map(
              (o, i) =>
                `${i + 1}. ${o.label}${o.description ? `: ${o.description}` : ""}`,
            ),
            FREE_TEXT,
          ];
          const choice = options.length
            ? await ctx.ui.select(q.question, labels, { signal })
            : FREE_TEXT;
          if (signal?.aborted)
            return pack({ status: "cancelled", answers: [] });
          if (choice === undefined)
            return pack({ status: "dismissed", answers: [] });
          const index = labels.indexOf(choice);
          if (index < 0) return pack({ status: "dismissed", answers: [] });
          const custom = index === options.length;
          const value = custom
            ? await ctx.ui.input(q.question, "Type your answer", { signal })
            : options[index]?.label;
          if (signal?.aborted)
            return pack({ status: "cancelled", answers: [] });
          if (!value?.trim()) return pack({ status: "dismissed", answers: [] });
          answers.push({
            id: q.id,
            question: q.question,
            answer: value.trim(),
            wasCustom: custom,
            selectedIndex: custom ? undefined : index + 1,
          });
        }
        return pack({ status: "answered", answers });
      }
      if (ctx.mode !== "tui")
        return pack({ status: "unavailable", answers: [] });

      const outcome = await ctx.ui.custom<Outcome>(
        (tui, theme, _keys, done) => {
          const answers = new Map<string, Answer>();
          let questionIndex = 0;
          let optionIndex = 0;
          let editing = false;
          let finished = false;
          const editor = new Editor(tui, {
            borderColor: (text) => theme.fg("accent", text),
            selectList: {
              selectedPrefix: (text) => theme.fg("accent", text),
              selectedText: (text) => theme.fg("accent", text),
              description: (text) => theme.fg("muted", text),
              scrollInfo: (text) => theme.fg("dim", text),
              noMatch: (text) => theme.fg("warning", text),
            },
          });
          const finish = (value: Outcome) => {
            if (finished) return;
            finished = true;
            signal?.removeEventListener("abort", cancel);
            done(value);
          };
          const cancel = () => finish({ status: "cancelled", answers: [] });
          signal?.addEventListener("abort", cancel, { once: true });
          if (signal?.aborted) queueMicrotask(cancel);
          const refresh = () => tui.requestRender();
          const go = (index: number) => {
            questionIndex = Math.max(0, Math.min(questions.length, index));
            const q = questions[questionIndex];
            const saved = q ? answers.get(q.id) : undefined;
            optionIndex = saved?.selectedIndex ? saved.selectedIndex - 1 : 0;
            editing = !!q && (!q.options?.length || saved?.wasCustom === true);
            editor.setText(saved?.wasCustom ? saved.answer : "");
            refresh();
          };
          const save = (answer: string, custom: boolean, index?: number) => {
            const q = questions[questionIndex];
            answers.set(q.id, {
              id: q.id,
              question: q.question,
              answer,
              wasCustom: custom,
              selectedIndex: index,
            });
            go(questionIndex + 1);
          };
          const choose = (index: number) => {
            const options = questions[questionIndex].options ?? [];
            if (index === options.length) {
              optionIndex = index;
              editing = true;
              const saved = answers.get(questions[questionIndex].id);
              editor.setText(saved?.wasCustom ? saved.answer : "");
              refresh();
            } else if (options[index])
              save(options[index].label, false, index + 1);
          };
          editor.onSubmit = (value) => {
            if (value.trim()) save(value.trim(), true);
          };
          go(0);
          return {
            handleInput(data: string) {
              if (finished) return;
              if (matchesKey(data, Key.tab)) {
                go((questionIndex + 1) % (questions.length + 1));
                return;
              }
              if (matchesKey(data, Key.shift("tab"))) {
                go(questionIndex === 0 ? questions.length : questionIndex - 1);
                return;
              }
              if (editing) {
                if (matchesKey(data, Key.escape)) {
                  editing = false;
                  refresh();
                  return;
                }
                editor.handleInput(data);
                refresh();
                return;
              }
              if (matchesKey(data, Key.escape)) {
                finish({ status: "dismissed", answers: [] });
                return;
              }
              if (matchesKey(data, Key.left)) {
                go(questionIndex - 1);
                return;
              }
              if (matchesKey(data, Key.right)) {
                go(questionIndex + 1);
                return;
              }
              if (questionIndex === questions.length) {
                if (matchesKey(data, Key.enter)) {
                  const missing = questions.findIndex(
                    (q) => !answers.has(q.id),
                  );
                  if (missing >= 0) go(missing);
                  else
                    finish({
                      status: "answered",
                      answers: questions.map((q) => answers.get(q.id)!),
                    });
                }
                return;
              }
              const count = (questions[questionIndex].options?.length ?? 0) + 1;
              if (matchesKey(data, Key.up))
                optionIndex = (optionIndex + count - 1) % count;
              else if (matchesKey(data, Key.down))
                optionIndex = (optionIndex + 1) % count;
              else if (/^[1-6]$/.test(data)) choose(Number(data) - 1);
              else if (matchesKey(data, Key.enter)) choose(optionIndex);
              refresh();
            },
            render(width: number) {
              width = Math.max(1, width);
              const lines: string[] = [theme.fg("accent", "─".repeat(width))];
              const add = (text: string) =>
                lines.push(...wrapTextWithAnsi(text, width));
              const q = questions[questionIndex];
              if (!q) {
                add(theme.bold("Review answers"));
                questions.forEach((q) =>
                  add(
                    `${q.question}: ${answers.get(q.id)?.answer ?? "(unanswered)"}`,
                  ),
                );
                add(
                  theme.fg(
                    "dim",
                    "Enter submit • Shift+Tab or ← edit • Esc dismiss",
                  ),
                );
              } else {
                add(
                  theme.fg(
                    "accent",
                    `Question ${questionIndex + 1}/${questions.length}`,
                  ),
                );
                add(theme.bold(q.question));
                const options = [
                  ...(q.options ?? []),
                  { label: FREE_TEXT, description: undefined },
                ];
                options.forEach((option, i) => {
                  add(
                    theme.fg(
                      i === optionIndex ? "accent" : "text",
                      `${i === optionIndex ? "❯" : " "} ${i + 1}. ${option.label}`,
                    ),
                  );
                  if (option.description)
                    add(theme.fg("muted", `   ${option.description}`));
                });
                if (editing) lines.push(...editor.render(width));
                add(
                  theme.fg(
                    "dim",
                    editing
                      ? "Enter save • Esc choices • Tab/Shift+Tab questions"
                      : "↑↓ or number choose • Enter confirm • Tab/Shift+Tab questions • Esc dismiss",
                  ),
                );
              }
              lines.push(theme.fg("accent", "─".repeat(width)));
              return lines.map((line) => truncateToWidth(line, width));
            },
            invalidate() {
              editor.invalidate();
            },
            dispose() {
              signal?.removeEventListener("abort", cancel);
            },
          };
        },
      );
      return pack(
        signal?.aborted ? { status: "cancelled", answers: [] } : outcome,
      );
    },
    renderCall(args, theme) {
      const questions =
        "questions" in args ? args.questions : [{ question: args.question }];
      return new Text(
        theme.fg("toolTitle", theme.bold("ask_user ")) +
          questions.map((q) => q.question).join("\n"),
        0,
        0,
      );
    },
    renderResult(result, _options, theme) {
      const details = result.details as Outcome | undefined;
      const text =
        details?.status === "answered"
          ? details.answers.map((a) => `${a.question}: ${a.answer}`).join("\n")
          : `ask_user ${details?.status ?? "unavailable"}`;
      return new Text(
        theme.fg(details?.status === "answered" ? "success" : "warning", text),
        0,
        0,
      );
    },
  });
}
