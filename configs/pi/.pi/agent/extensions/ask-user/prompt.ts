/** Model-facing copy and result text for the ask_user tool. */

export const ASK_USER_PARAMETER_DESCRIPTIONS = {
  question: "The single question to ask the user",
  options:
    "Exactly 2 to 5 answer options. A free-form `Write my own answer` option is appended automatically; do not include an Other or free-form option yourself.",
  optionLabel: "Short label displayed for this answer option",
  optionDescription: "Optional description displayed below this answer option",
};

export const ASK_USER_TOOL_DESCRIPTION =
  "Ask the user one single-select question with 2-5 options. The UI always adds a free-form `Write my own answer` path, and the user may dismiss the question. Use one question per call.";

export const ASK_USER_PROMPT_SNIPPET =
  "Ask one user question with 2-5 choices and a free-form answer path";

export const ASK_USER_PROMPT_GUIDELINES = [
  "Use ask_user when a question has a useful finite set of likely answers.",
  "Call ask_user for exactly one question at a time; ask follow-up questions in later calls.",
  "Give ask_user 2-5 meaningful options and never add an Other or free-form option; `Write my own answer` is automatic.",
  "Treat ask_user dismissed, cancelled, and unavailable outcomes as having no answer; never assume a choice.",
];

export function buildAskUserResultMessage(
  outcome:
    | { kind: "unavailable" }
    | { kind: "cancelled" }
    | { kind: "dismissed" }
    | { kind: "custom"; answer: string }
    | { kind: "selected"; answer: string; index: number },
) {
  switch (outcome.kind) {
    case "unavailable":
      return "Interactive UI is unavailable, so ask_user could not be shown. No answer was selected or written; do not assume an answer. Ask the user in plain text instead.";
    case "cancelled":
      return "The ask_user interaction was cancelled because the agent run was aborted. No answer was selected or written; do not assume an answer.";
    case "dismissed":
      return "The user dismissed ask_user without answering. No answer was selected or written; do not assume an answer.";
    case "custom":
      return `The user wrote their own answer: ${outcome.answer}`;
    case "selected":
      return `The user selected option ${outcome.index}: ${outcome.answer}`;
  }
}
