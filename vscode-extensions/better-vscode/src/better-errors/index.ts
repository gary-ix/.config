import * as vscode from "vscode";

import { registerCopyErrorCommand } from "./ui/registerCopyErrorCommand";
import { registerCopyErrorCodeActionProvider } from "./ui/registerCopyErrorCodeActionProvider";

export function registerBetterErrors(context: vscode.ExtensionContext) {
	context.subscriptions.push(registerCopyErrorCommand(), registerCopyErrorCodeActionProvider());
}
