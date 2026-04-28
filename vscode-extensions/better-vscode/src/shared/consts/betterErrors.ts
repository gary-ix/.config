export const BETTER_ERRORS_COMMAND_PREFIX = "betterErrors";
export const BETTER_ERRORS_DISPLAY_PREFIX = "better-errors";

export const BETTER_ERRORS_COMMANDS = {
	copyError: `${BETTER_ERRORS_COMMAND_PREFIX}.copyError`,
} as const;

export const BETTER_ERRORS_COMMAND_TITLES = {
	copyError: `${BETTER_ERRORS_DISPLAY_PREFIX}: Copy Error`,
} as const;

export const BETTER_ERRORS_CONFIG = {
	root: "betterErrors",
	includeWorkspaceRelativePath: "includeWorkspaceRelativePath",
	includeSelection: "includeSelection",
	contextLineCount: "contextLineCount",
} as const;

export const BETTER_ERRORS_PROMPT_DEFAULTS = {
	instruction:
		"Help me fix this editor error. Keep the full raw diagnostic intact, explain the root cause in plain English, and suggest the smallest safe fix.",
	emptySelectionPlaceholder: "<no explicit selection>",
	emptyContextPlaceholder: "<no local context>",
} as const;
