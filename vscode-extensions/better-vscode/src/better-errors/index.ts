import * as vscode from "vscode";

import { registerCopyErrorCommand } from "./ui/registerCopyErrorCommand";
import { registerCopyErrorCodeLensProvider } from "./ui/registerCopyErrorCodeLensProvider";

export function registerBetterErrors(context: vscode.ExtensionContext) {
	context.subscriptions.push(registerCopyErrorCommand(), registerCopyErrorCodeLensProvider());
}
