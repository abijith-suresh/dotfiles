/** Model-facing instructions for the single ask_user interface. */
export const ASK_USER_TOOL_DESCRIPTION =
  "Ask one or more questions in a single interaction. Each question can include 2-5 suggested choices and always allows free text. Return all answers together after the user submits. Headless sessions return unavailable, and aborts return cancelled with no assumed answers.";
export const ASK_USER_PROMPT_SNIPPET =
  "Ask related questions together, with optional suggested choices and free text";
export const ASK_USER_PROMPT_GUIDELINES = [
  "Bundle related questions in one ask_user call. Use stable, unique question ids.",
  "Provide 2-5 suggested choices when useful; omit options for a free-text question. Do not add an Other option.",
  "Never infer an answer from a dismissed, cancelled or unavailable interaction.",
];
