export type BetterErrorPosition = {
	line: number;
	character: number;
};

export type BetterErrorRange = {
	start: BetterErrorPosition;
	end: BetterErrorPosition;
};

export type BetterErrorSeverity =
	| "error"
	| "warning"
	| "information"
	| "hint"
	| "unknown";

export type BetterErrorRelatedInformation = {
	filePath: string;
	range: BetterErrorRange;
	message: string;
};

export type BetterErrorDiagnostic = {
	filePath: string;
	documentLanguageId: string;
	range: BetterErrorRange;
	selection: BetterErrorRange;
	severity: BetterErrorSeverity;
	message: string;
	rawMessage: string;
	source?: string;
	code?: string;
	relatedInformation: readonly BetterErrorRelatedInformation[];
	selectedText: string;
	contextText: string;
};

export type BetterErrorPromptInput = {
	diagnostic: BetterErrorDiagnostic;
};
