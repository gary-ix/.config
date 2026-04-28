import * as vscode from "vscode";

import { BETTER_ERRORS_COMMANDS, BETTER_ERRORS_COMMAND_TITLES } from "../../shared/consts/betterErrors";

export function registerCopyErrorCodeActionProvider(): vscode.Disposable {
	return vscode.languages.registerCodeActionsProvider(
		[
			{ scheme: "file" },
			{ scheme: "untitled" },
		],
		{
			provideCodeActions(document, range, context) {
				if (context.only && !context.only.contains(vscode.CodeActionKind.QuickFix)) {
					return undefined;
				}

				const matchingDiagnostics = context.diagnostics.filter(
					(diagnostic) => diagnostic.range.intersection(range) !== undefined,
				);

				if (matchingDiagnostics.length === 0) {
					return undefined;
				}

				const action = new vscode.CodeAction(
					BETTER_ERRORS_COMMAND_TITLES.copyError,
					vscode.CodeActionKind.QuickFix,
				);

				action.command = {
					command: BETTER_ERRORS_COMMANDS.copyError,
					title: BETTER_ERRORS_COMMAND_TITLES.copyError,
					arguments: [document.uri, matchingDiagnostics[0]?.range],
				};
				action.diagnostics = matchingDiagnostics;
				action.isPreferred = false;

				return [action];
			},
		},
		{
			providedCodeActionKinds: [vscode.CodeActionKind.QuickFix],
		},
	);
}
