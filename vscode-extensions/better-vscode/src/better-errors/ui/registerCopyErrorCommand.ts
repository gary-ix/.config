import * as vscode from "vscode";

import { BETTER_ERRORS_COMMANDS } from "../../shared/consts/betterErrors";
import { copyActiveError } from "./copyActiveError";

export function registerCopyErrorCommand(): vscode.Disposable {
	return vscode.commands.registerCommand(
		BETTER_ERRORS_COMMANDS.copyError,
		async (_uri?: vscode.Uri, targetRange?: vscode.Range) => {
			const editor = vscode.window.activeTextEditor;

			if (!editor) {
				void vscode.window.showWarningMessage("Open a file before copying an error.");
				return;
			}

			const didCopy = await copyActiveError(editor, targetRange);

			if (!didCopy) {
				void vscode.window.showWarningMessage("No diagnostic found at the current cursor or selection.");
				return;
			}

			void vscode.window.showInformationMessage("Copied error prompt.");
		},
	);
}
