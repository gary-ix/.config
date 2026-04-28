import * as vscode from "vscode";

import {
	BETTER_ERRORS_COMMANDS,
	BETTER_ERRORS_COMMAND_TITLES,
} from "../../shared/consts/betterErrors";
import { selectCodeLensDiagnostics } from "../diagnostics/selectCodeLensDiagnostics";

export function registerCopyErrorCodeLensProvider(): vscode.Disposable {
	const onDidChangeCodeLenses = new vscode.EventEmitter<void>();

	const provider = vscode.languages.registerCodeLensProvider(
		[
			{ scheme: "file" },
			{ scheme: "untitled" },
		],
		{
			onDidChangeCodeLenses: onDidChangeCodeLenses.event,
			provideCodeLenses(document) {
				const diagnostics = selectCodeLensDiagnostics(
					vscode.languages.getDiagnostics(document.uri).map((diagnostic) => ({
						diagnostic,
						range: {
							start: {
								line: diagnostic.range.start.line,
								character: diagnostic.range.start.character,
							},
							end: {
								line: diagnostic.range.end.line,
								character: diagnostic.range.end.character,
							},
						},
						severity: formatSeverity(diagnostic.severity),
					})),
				);

				return diagnostics.map(
					(diagnostic) =>
						new vscode.CodeLens(diagnostic.range, {
							command: BETTER_ERRORS_COMMANDS.copyError,
							title: BETTER_ERRORS_COMMAND_TITLES.copyError,
							arguments: [document.uri, diagnostic.range],
						}),
				);
			},
		},
	);

	const diagnosticsSubscription = vscode.languages.onDidChangeDiagnostics(() => {
		onDidChangeCodeLenses.fire();
	});

	return vscode.Disposable.from(provider, diagnosticsSubscription, onDidChangeCodeLenses);
}

function formatSeverity(severity: vscode.DiagnosticSeverity):
	| "error"
	| "warning"
	| "information"
	| "hint"
	| "unknown" {
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
