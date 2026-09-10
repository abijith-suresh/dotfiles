import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  Editor,
  type EditorTheme,
  Key,
  matchesKey,
  parseKey,
  Text,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";
import {
  ASK_USER_PARAMETER_DESCRIPTIONS,
  ASK_USER_PROMPT_GUIDELINES,
  ASK_USER_PROMPT_SNIPPET,
  ASK_USER_TOOL_DESCRIPTION,
  buildAskUserResultMessage,
} from "./prompt.ts";

const MIN_OPTIONS = 2;
const MAX_OPTIONS = 5;
const WRITE_OWN_ANSWER_LABEL = "Write my own answer";

const OptionSchema = Type.Object({
  label: Type.String({
    description: ASK_USER_PARAMETER_DESCRIPTIONS.optionLabel,
  }),
  description: Type.Optional(
    Type.String({
      description: ASK_USER_PARAMETER_DESCRIPTIONS.optionDescription,
    }),
  ),
});

const AskUserParams = Type.Object({
  question: Type.String({
    description: ASK_USER_PARAMETER_DESCRIPTIONS.question,
  }),
  options: Type.Array(OptionSchema, {
    minItems: MIN_OPTIONS,
    maxItems: MAX_OPTIONS,
    description: ASK_USER_PARAMETER_DESCRIPTIONS.options,
  }),
});

type AskUserInput = Static<typeof AskUserParams>;
type AskUserStatus =
  "selected" | "custom" | "dismissed" | "cancelled" | "unavailable";

interface AskUserDetails {
  status: AskUserStatus;
  question: string;
  options: AskUserInput["options"];
  answer: string | null;
  wasCustom: boolean;
  cancelled: boolean;
  selectedIndex?: number;
}

interface DisplayOption {
  label: string;
  description?: string;
  isCustom?: boolean;
}

type TuiSelection =
  | { status: "selected"; answer: string; index: number }
  | { status: "custom"; answer: string }
  | { status: "dismissed" }
  | { status: "cancelled" };

function createDetails(
  params: AskUserInput,
  status: AskUserStatus,
  answer: string | null,
  selectedIndex?: number,
) {
  return {
    status,
    question: params.question,
    options: params.options,
    answer,
    wasCustom: status === "custom",
    cancelled: status === "cancelled",
    selectedIndex,
  };
}

function result(
  params: AskUserInput,
  status: AskUserStatus,
  message: string,
  answer: string | null = null,
  selectedIndex?: number,
) {
  return {
    content: [{ type: "text" as const, text: message }],
    details: createDetails(params, status, answer, selectedIndex),
  };
}

function renderWrappedWithPrefix(
  lines: string[],
  prefix: string,
  text: string,
  width: number,
) {
  const prefixWidth = visibleWidth(prefix);
  if (prefixWidth >= width) {
    lines.push(truncateToWidth(prefix + text, width));
    return;
  }

  const wrapped = wrapTextWithAnsi(text, width - prefixWidth);
  for (const [index, line] of wrapped.entries()) {
    lines.push(`${index === 0 ? prefix : " ".repeat(prefixWidth)}${line}`);
  }
}

function optionForDialog(option: DisplayOption, index: number) {
  const description = option.description ? ` — ${option.description}` : "";
  return `${index + 1}. ${option.label}${description}`;
}

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description: ASK_USER_TOOL_DESCRIPTION,
    promptSnippet: ASK_USER_PROMPT_SNIPPET,
    promptGuidelines: ASK_USER_PROMPT_GUIDELINES,
    parameters: AskUserParams,
    executionMode: "sequential",

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      if (
        params.options.length < MIN_OPTIONS ||
        params.options.length > MAX_OPTIONS
      ) {
        throw new Error(
          `ask_user requires between ${MIN_OPTIONS} and ${MAX_OPTIONS} options (got ${params.options.length}).`,
        );
      }

      if (!ctx.hasUI) {
        return result(
          params,
          "unavailable",
          buildAskUserResultMessage({ kind: "unavailable" }),
        );
      }

      if (signal?.aborted) {
        return result(
          params,
          "cancelled",
          buildAskUserResultMessage({ kind: "cancelled" }),
        );
      }

      if (ctx.mode === "rpc") {
        const options: DisplayOption[] = [
          ...params.options,
          { label: WRITE_OWN_ANSWER_LABEL, isCustom: true },
        ];
        const choice = await ctx.ui.select(
          params.question,
          options.map(optionForDialog),
          { signal },
        );

        if (signal?.aborted) {
          return result(
            params,
            "cancelled",
            buildAskUserResultMessage({ kind: "cancelled" }),
          );
        }
        if (choice === undefined) {
          return result(
            params,
            "dismissed",
            buildAskUserResultMessage({ kind: "dismissed" }),
          );
        }

        const choiceIndex = options.findIndex(
          (option, index) => optionForDialog(option, index) === choice,
        );
        const selected = options[choiceIndex];
        if (!selected) {
          return result(
            params,
            "dismissed",
            buildAskUserResultMessage({ kind: "dismissed" }),
          );
        }

        if (selected.isCustom) {
          const answer = await ctx.ui.input(
            "Write your own answer",
            "Type your answer...",
            { signal },
          );
          if (signal?.aborted) {
            return result(
              params,
              "cancelled",
              buildAskUserResultMessage({ kind: "cancelled" }),
            );
          }
          if (answer === undefined || answer.trim() === "") {
            return result(
              params,
              "dismissed",
              buildAskUserResultMessage({ kind: "dismissed" }),
            );
          }
          const trimmedAnswer = answer.trim();
          return result(
            params,
            "custom",
            buildAskUserResultMessage({
              kind: "custom",
              answer: trimmedAnswer,
            }),
            trimmedAnswer,
          );
        }

        return result(
          params,
          "selected",
          buildAskUserResultMessage({
            kind: "selected",
            answer: selected.label,
            index: choiceIndex + 1,
          }),
          selected.label,
          choiceIndex + 1,
        );
      }

      if (ctx.mode !== "tui") {
        return result(
          params,
          "unavailable",
          buildAskUserResultMessage({ kind: "unavailable" }),
        );
      }

      const options: DisplayOption[] = [
        ...params.options,
        { label: WRITE_OWN_ANSWER_LABEL, isCustom: true },
      ];
      const selection = await ctx.ui.custom<TuiSelection>(
        (tui, theme, _keybindings, done) => {
          let optionIndex = 0;
          let editMode = false;
          let cachedLines: string[] | undefined;
          let cachedWidth: number | undefined;
          let settled = false;

          function finish(value: TuiSelection) {
            if (settled) return;
            settled = true;
            signal?.removeEventListener("abort", cancel);
            done(value);
          }

          function cancel() {
            finish({ status: "cancelled" });
          }

          signal?.addEventListener("abort", cancel, { once: true });
          if (signal?.aborted) queueMicrotask(cancel);

          const editorTheme: EditorTheme = {
            borderColor: (text) => theme.fg("accent", text),
            selectList: {
              selectedPrefix: (text) => theme.fg("accent", text),
              selectedText: (text) => theme.fg("accent", text),
              description: (text) => theme.fg("muted", text),
              scrollInfo: (text) => theme.fg("dim", text),
              noMatch: (text) => theme.fg("warning", text),
            },
          };
          const editor = new Editor(tui, editorTheme);

          editor.onSubmit = (value) => {
            const answer = value.trim();
            if (answer) {
              finish({ status: "custom", answer });
              return;
            }
            editMode = false;
            editor.setText("");
            refresh();
          };

          function refresh() {
            cachedLines = undefined;
            cachedWidth = undefined;
            tui.requestRender();
          }

          function choose(index: number) {
            const selected = options[index];
            if (!selected) return;
            if (selected.isCustom) {
              optionIndex = index;
              editMode = true;
              editor.setText("");
              refresh();
              return;
            }
            finish({
              status: "selected",
              answer: selected.label,
              index: index + 1,
            });
          }

          function handleInput(data: string) {
            if (editMode) {
              if (matchesKey(data, Key.escape)) {
                editMode = false;
                editor.setText("");
                refresh();
                return;
              }
              editor.handleInput(data);
              refresh();
              return;
            }

            if (matchesKey(data, Key.up)) {
              optionIndex = (optionIndex - 1 + options.length) % options.length;
              refresh();
              return;
            }
            if (matchesKey(data, Key.down)) {
              optionIndex = (optionIndex + 1) % options.length;
              refresh();
              return;
            }

            const key = parseKey(data) ?? data;
            if (
              key.length === 1 &&
              key >= "1" &&
              key <= String(options.length)
            ) {
              choose(Number(key) - 1);
              return;
            }

            if (matchesKey(data, Key.enter)) {
              choose(optionIndex);
              return;
            }
            if (matchesKey(data, Key.escape)) {
              finish({ status: "dismissed" });
            }
          }

          function render(width: number) {
            const renderWidth = Math.max(1, width);
            if (cachedLines && cachedWidth === renderWidth) return cachedLines;
            const lines: string[] = [];
            lines.push(theme.fg("accent", "─".repeat(renderWidth)));
            renderWrappedWithPrefix(
              lines,
              " ",
              theme.fg("text", theme.bold(params.question)),
              renderWidth,
            );
            lines.push("");

            options.forEach((option, index) => {
              const selected = index === optionIndex;
              const prefix = selected ? theme.fg("accent", " ❯ ") : "   ";
              const marker = option.isCustom ? "✎" : `${index + 1}.`;
              const label = `${marker} ${option.label}${
                option.isCustom && editMode ? " ✎" : ""
              }`;
              const color = selected
                ? "accent"
                : option.isCustom
                  ? "muted"
                  : "text";
              renderWrappedWithPrefix(
                lines,
                prefix,
                theme.fg(color, label),
                renderWidth,
              );
              if (option.description) {
                renderWrappedWithPrefix(
                  lines,
                  "      ",
                  theme.fg("muted", option.description),
                  renderWidth,
                );
              }
            });

            if (editMode) {
              lines.push("");
              renderWrappedWithPrefix(
                lines,
                " ",
                theme.fg("muted", "Your answer:"),
                renderWidth,
              );
              for (const line of editor.render(Math.max(1, renderWidth - 2))) {
                lines.push(truncateToWidth(` ${line}`, renderWidth));
              }
            }

            lines.push("");
            renderWrappedWithPrefix(
              lines,
              " ",
              theme.fg(
                "dim",
                editMode
                  ? "Enter submit • Esc back to options"
                  : `↑↓ or 1-${options.length} select • Enter confirm • Esc dismiss`,
              ),
              renderWidth,
            );
            lines.push(theme.fg("accent", "─".repeat(renderWidth)));

            cachedLines = lines.map((line) =>
              truncateToWidth(line, renderWidth),
            );
            cachedWidth = renderWidth;
            return cachedLines;
          }

          return {
            render,
            invalidate: () => {
              cachedLines = undefined;
              cachedWidth = undefined;
            },
            handleInput,
            dispose: () => signal?.removeEventListener("abort", cancel),
          };
        },
      );

      if (selection.status === "cancelled") {
        return result(
          params,
          "cancelled",
          buildAskUserResultMessage({ kind: "cancelled" }),
        );
      }
      if (selection.status === "dismissed") {
        return result(
          params,
          "dismissed",
          buildAskUserResultMessage({ kind: "dismissed" }),
        );
      }
      if (selection.status === "custom") {
        return result(
          params,
          "custom",
          buildAskUserResultMessage({
            kind: "custom",
            answer: selection.answer,
          }),
          selection.answer,
        );
      }
      return result(
        params,
        "selected",
        buildAskUserResultMessage({
          kind: "selected",
          answer: selection.answer,
          index: selection.index,
        }),
        selection.answer,
        selection.index,
      );
    },

    renderCall(args, theme, _context) {
      let text = theme.fg("toolTitle", theme.bold("ask_user "));
      text += theme.fg("muted", args.question);
      if (args.options.length > 0) {
        const options = [
          ...args.options.map(
            (option, index) => `${index + 1}. ${option.label}`,
          ),
          `${args.options.length + 1}. ${WRITE_OWN_ANSWER_LABEL}`,
        ];
        text += `\n${theme.fg("dim", `  ${options.join("  ")}`)}`;
      }
      return new Text(text, 0, 0);
    },

    renderResult(toolResult, _options, theme, _context) {
      const details = toolResult.details as AskUserDetails | undefined;
      if (!details) {
        const first = toolResult.content[0];
        return new Text(first?.type === "text" ? first.text : "", 0, 0);
      }

      if (details.status === "unavailable") {
        return new Text(
          theme.fg("warning", "Interactive UI unavailable"),
          0,
          0,
        );
      }
      if (details.status === "cancelled") {
        return new Text(theme.fg("warning", "✗ cancelled"), 0, 0);
      }
      if (details.status === "dismissed") {
        return new Text(theme.fg("warning", "✗ dismissed"), 0, 0);
      }
      if (details.status === "custom") {
        return new Text(
          theme.fg("success", "✓ ") +
            theme.fg("muted", "(wrote) ") +
            theme.fg("accent", details.answer ?? ""),
          0,
          0,
        );
      }

      const selectedIndex = details.selectedIndex ?? 0;
      const selected = selectedIndex > 0 ? `${selectedIndex}. ` : "";
      return new Text(
        theme.fg("success", "✓ ") +
          theme.fg("accent", `${selected}${details.answer ?? ""}`),
        0,
        0,
      );
    },
  });
}
