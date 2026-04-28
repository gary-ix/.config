import type { BetterErrorPromptInput } from "../../shared/contracts/betterErrors";
import { BETTER_ERRORS_PROMPT_DEFAULTS } from "../../shared/consts/betterErrors";

export function buildCopyErrorPrompt({ diagnostic }: BetterErrorPromptInput): string {
	return trimTrailingBlankLines([
		...buildInstructionSection(),
		...buildDiagnosticMetadataSection(diagnostic),
		...buildCodeSection({
			label: "Selected code:",
			language: diagnostic.documentLanguageId,
			content: withFallback(
				diagnostic.selectedText,
				BETTER_ERRORS_PROMPT_DEFAULTS.emptySelectionPlaceholder,
			),
		}),
		...buildCodeSection({
			label: "Local context:",
			language: diagnostic.documentLanguageId,
			content: withFallback(
				diagnostic.contextText,
				BETTER_ERRORS_PROMPT_DEFAULTS.emptyContextPlaceholder,
			),
		}),
		...buildRelatedInformationSection(diagnostic.relatedInformation),
	]).join("\n");
}

function buildInstructionSection(): string[] {
	return [BETTER_ERRORS_PROMPT_DEFAULTS.instruction, ""];
}

function buildDiagnosticMetadataSection(
	diagnostic: BetterErrorPromptInput["diagnostic"],
): string[] {
	return filterEmptyLines([
		"```yaml",
		`kind: better_errors_prompt`,
		`language: ${diagnostic.documentLanguageId}`,
		`file_path: ${diagnostic.filePath}`,
		`range: ${formatRange(diagnostic.range)}`,
		`selection_range: ${formatRange(diagnostic.selection)}`,
		`severity: ${diagnostic.severity}`,
		diagnostic.source ? `source: ${diagnostic.source}` : undefined,
		diagnostic.code ? `code: ${diagnostic.code}` : undefined,
		"raw_error: |",
		...indentBlock(diagnostic.rawMessage),
		"```",
		"",
	]);
}

function buildCodeSection({
	label,
	language,
	content,
}: {
	label: string;
	language: string;
	content: string;
}): string[] {
	return [label, `\`\`\`${language}`, content, "```", ""];
}

function buildRelatedInformationSection(
	relatedInformation: BetterErrorPromptInput["diagnostic"]["relatedInformation"],
): string[] {
	if (relatedInformation.length === 0) {
		return [];
	}

	return [
		"Related diagnostic info:",
		...relatedInformation.map((item) => {
			const range = formatRange(item.range);

			return `- ${item.filePath}:${range} ${item.message}`;
		}),
	];
}

function withFallback(value: string, fallback: string): string {
	return value.length > 0 ? value : fallback;
}

function filterEmptyLines(lines: Array<string | undefined>): string[] {
	return lines.filter((value): value is string => Boolean(value));
}

function trimTrailingBlankLines(lines: string[]): string[] {
	const endIndex = [...lines].reverse().findIndex((line) => line.length > 0);

	return endIndex === -1 ? [] : lines.slice(0, lines.length - endIndex);
}

function formatRange(range: BetterErrorPromptInput["diagnostic"]["range"]): string {
	return `${range.start.line + 1}:${range.start.character + 1}-${range.end.line + 1}:${range.end.character + 1}`;
}

function indentBlock(text: string): string[] {
	return text.split("\n").map((line) => `  ${line}`);
}
