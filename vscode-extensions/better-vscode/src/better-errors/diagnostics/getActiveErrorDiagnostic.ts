import * as vscode from "vscode";

import type {
	BetterErrorDiagnostic,
	BetterErrorPosition,
	BetterErrorRange,
	BetterErrorSeverity,
} from "../../shared/contracts/betterErrors";
import { BETTER_ERRORS_CONFIG } from "../../shared/consts/betterErrors";
import { selectDiagnostic } from "./selectDiagnostic";

export function getActiveErrorDiagnostic(
	editor: vscode.TextEditor,
	targetRange?: vscode.Range,
): BetterErrorDiagnostic | undefined {
	const diagnostics = vscode.languages.getDiagnostics(editor.document.uri);
	const selection = editor.selection;
	const effectiveRange = targetRange ?? selection;
	const effectiveActivePosition = targetRange?.start ?? selection.active;
	const diagnostic = selectDiagnostic(
		diagnostics.map((item) => ({
			diagnostic: item,
			range: toRange(item.range),
			severity: formatSeverity(item.severity),
		})),
		toRange(effectiveRange),
		toPosition(effectiveActivePosition),
	);

	if (!diagnostic) {
		return undefined;
	}

	const filePath = getFilePath(editor.document.uri);
	const contextRange = expandRangeByLines(
		editor.document,
		diagnostic.range,
		getContextLineCount(),
	);

	return {
		filePath,
		documentLanguageId: editor.document.languageId,
		range: toRange(diagnostic.range),
		selection: toRange(selection),
		severity: formatSeverity(diagnostic.severity),
		message: diagnostic.message,
		rawMessage: diagnostic.message,
		source: diagnostic.source,
		code: normalizeDiagnosticCode(diagnostic.code),
		relatedInformation: (diagnostic.relatedInformation ?? []).map((item) => ({
			filePath: getFilePath(item.location.uri),
			range: toRange(item.location.range),
			message: item.message,
		})),
		selectedText: getSelectedText(editor),
		contextText: editor.document.getText(contextRange),
	};
}

function expandRangeByLines(
	document: vscode.TextDocument,
	range: vscode.Range,
	paddingLineCount: number,
): vscode.Range {
	const startLine = Math.max(0, range.start.line - paddingLineCount);
	const endLine = Math.min(document.lineCount - 1, range.end.line + paddingLineCount);

	return new vscode.Range(
		new vscode.Position(startLine, 0),
		document.lineAt(endLine).range.end,
	);
}

function getContextLineCount(): number {
	return vscode.workspace
		.getConfiguration(BETTER_ERRORS_CONFIG.root)
		.get<number>(BETTER_ERRORS_CONFIG.contextLineCount, 12);
}

function getFilePath(uri: vscode.Uri): string {
	const includeWorkspaceRelativePath = vscode.workspace
		.getConfiguration(BETTER_ERRORS_CONFIG.root)
		.get<boolean>(BETTER_ERRORS_CONFIG.includeWorkspaceRelativePath, true);

	return includeWorkspaceRelativePath
		? vscode.workspace.asRelativePath(uri, false)
		: uri.fsPath;
}

function getSelectedText(editor: vscode.TextEditor): string {
	const includeSelection = vscode.workspace
		.getConfiguration(BETTER_ERRORS_CONFIG.root)
		.get<boolean>(BETTER_ERRORS_CONFIG.includeSelection, true);

	return includeSelection ? editor.document.getText(editor.selection) : "";
}

function toPosition(position: vscode.Position): BetterErrorPosition {
	return {
		line: position.line,
		character: position.character,
	};
}

function toRange(range: vscode.Range | vscode.Selection): BetterErrorRange {
	return {
		start: toPosition(range.start),
		end: toPosition(range.end),
	};
}

function formatSeverity(severity: vscode.DiagnosticSeverity): BetterErrorSeverity {
	switch (severity) {
		case vscode.DiagnosticSeverity.Error:
			return "error";
		case vscode.DiagnosticSeverity.Warning:
			return "warning";
		case vscode.DiagnosticSeverity.Information:
			return "information";
		case vscode.DiagnosticSeverity.Hint:
			return "hint";
		default:
			return "unknown";
	}
}

function normalizeDiagnosticCode(code: vscode.Diagnostic["code"]): string | undefined {
	if (typeof code === "string") {
		return code;
	}

	if (typeof code === "number") {
		return String(code);
	}

	if (code && typeof code === "object" && "value" in code) {
		return String(code.value);
	}

	return undefined;
}
