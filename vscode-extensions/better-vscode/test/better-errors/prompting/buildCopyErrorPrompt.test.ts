import test from "node:test";
import assert from "node:assert/strict";

import { buildCopyErrorPrompt } from "../../../src/better-errors/prompting/buildCopyErrorPrompt";
import type { BetterErrorDiagnostic } from "../../../src/shared/contracts/betterErrors";

test("buildCopyErrorPrompt preserves the raw diagnostic and includes metadata", () => {
	const diagnostic: BetterErrorDiagnostic = {
		filePath: "src/app.ts",
		documentLanguageId: "typescript",
		range: {
			start: { line: 4, character: 2 },
			end: { line: 4, character: 18 },
		},
		selection: {
			start: { line: 4, character: 0 },
			end: { line: 6, character: 1 },
		},
		severity: "error",
		message: "Type 'string' is not assignable to type 'number'.",
		rawMessage: "Type 'string' is not assignable to type 'number'.\n  The expected type comes from property 'count'.",
		source: "ts",
		code: "2322",
		relatedInformation: [
			{
				filePath: "src/types.ts",
				range: {
					start: { line: 0, character: 13 },
					end: { line: 0, character: 18 },
				},
				message: "'count' is declared here.",
			},
		],
		selectedText: "  count: value,\n",
		contextText: "const payload = {\n  count: value,\n};\n",
	};

	const prompt = buildCopyErrorPrompt({ diagnostic });

	assert.match(prompt, /file_path: src\/app\.ts/);
	assert.match(prompt, /language: typescript/);
	assert.match(prompt, /range: 5:3-5:19/);
	assert.match(prompt, /selection_range: 5:1-7:2/);
	assert.match(prompt, /severity: error/);
	assert.match(prompt, /source: ts/);
	assert.match(prompt, /code: 2322/);
	assert.match(
		prompt,
		/raw_error: \|\n  Type 'string' is not assignable to type 'number'\.\n    The expected type comes from property 'count'\./,
	);
	assert.match(prompt, /```typescript\n  count: value,\n\n```/);
	assert.match(prompt, /Local context:\n```typescript\nconst payload = \{\n  count: value,\n\};\n\n```/);
	assert.match(prompt, /- src\/types\.ts:1:14-1:19 'count' is declared here\./);
});

test("buildCopyErrorPrompt uses placeholders for empty selection and context", () => {
	const diagnostic: BetterErrorDiagnostic = {
		filePath: "main.py",
		documentLanguageId: "python",
		range: {
			start: { line: 0, character: 0 },
			end: { line: 0, character: 5 },
		},
		selection: {
			start: { line: 0, character: 0 },
			end: { line: 0, character: 0 },
		},
		severity: "warning",
		message: "Unused variable 'x'",
		rawMessage: "Unused variable 'x'",
		relatedInformation: [],
		selectedText: "",
		contextText: "",
	};

	const prompt = buildCopyErrorPrompt({ diagnostic });

	assert.match(prompt, /<no explicit selection>/);
	assert.match(prompt, /<no local context>/);
	assert.doesNotMatch(prompt, /Related diagnostic info:/);
	assert.doesNotMatch(prompt, /(^|\n)source: /m);
	assert.doesNotMatch(prompt, /(^|\n)code: /m);
	assert.match(prompt, /raw_error: \|\n  Unused variable 'x'/);
});
