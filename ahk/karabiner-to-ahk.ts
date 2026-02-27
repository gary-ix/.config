import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

/**
 * Sync AutoHotkey shortcuts from Karabiner complex modifications.
 *
 * Conversion model:
 * - Input: karabiner/karabiner.json
 * - Output: ahk/keyboard-shortcuts.ahk (managed block)
 *
 * Translation scope:
 * - Only stateless `basic` manipulators are translated.
 * - Stateful/tap-hold/variable-driven mappings are intentionally skipped.
 * - Existing AHK content outside the managed block is preserved.
 */

type KarabinerConfig = {
	profiles?: Array<{
		selected?: boolean;
		complex_modifications?: {
			rules?: Array<{
				enabled?: boolean;
				description?: string;
				manipulators?: Manipulator[];
			}>;
		};
	}>;
};

type Manipulator = {
	type?: string;
	conditions?: unknown[];
	from?: {
		key_code?: string;
		modifiers?: {
			mandatory?: string[];
		};
	};
	to?: Array<{
		key_code?: string;
		modifiers?: string[];
		set_variable?: unknown;
	}>;
	to_if_alone?: unknown[];
	to_delayed_action?: unknown;
};

const ROOT_DIR = path.resolve(__dirname, "..");
const KARABINER_PATH = path.join(ROOT_DIR, "karabiner", "karabiner.json");
const AHK_PATH = path.join(ROOT_DIR, "ahk", "keyboard-shortcuts.ahk");

const BEGIN_MARKER = "; BEGIN AUTO-GENERATED FROM KARABINER";
const END_MARKER = "; END AUTO-GENERATED FROM KARABINER";

// Normalizes Karabiner modifier names to AHK v2 modifier symbols.
// The final order is enforced later to keep output deterministic.
const MODIFIER_SYMBOLS: Record<string, string> = {
	control: "^",
	left_control: "^",
	right_control: "^",
	option: "!",
	left_option: "!",
	right_option: "!",
	alt: "!",
	left_alt: "!",
	right_alt: "!",
	shift: "+",
	left_shift: "+",
	right_shift: "+",
	command: "#",
	left_command: "#",
	right_command: "#",
	windows: "#",
	left_windows: "#",
	right_windows: "#",
};

// Maps Karabiner key identifiers to friendly AHK names.
// Single letters/numbers and function keys are handled separately.
const AHK_KEY_NAMES: Record<string, string> = {
	spacebar: "Space",
	tab: "Tab",
	escape: "Escape",
	return_or_enter: "Enter",
	delete_or_backspace: "Backspace",
	delete_forward: "Delete",
	left_arrow: "Left",
	right_arrow: "Right",
	up_arrow: "Up",
	down_arrow: "Down",
	home: "Home",
	end: "End",
	page_up: "PgUp",
	page_down: "PgDn",
	caps_lock: "CapsLock",
};

function readKarabinerConfig(raw: string): KarabinerConfig {
	// Karabiner file is strict JSON, so plain JSON.parse is sufficient.
	return JSON.parse(raw) as KarabinerConfig;
}

function getSelectedProfile(config: KarabinerConfig) {
	const profiles = config.profiles ?? [];
	// Prefer explicit selected profile; fallback keeps script usable in backup files.
	return profiles.find((profile) => profile.selected) ?? profiles[0];
}

function normalizeAhkKey(keyCode: string): string {
	// AHK hotkeys use lowercase for single characters.
	if (/^[a-z0-9]$/i.test(keyCode)) {
		return keyCode.length === 1 ? keyCode.toLowerCase() : keyCode;
	}

	// Preserve canonical uppercase F-key names in generated output.
	if (/^f([1-9]|1[0-9]|2[0-4])$/i.test(keyCode)) {
		return keyCode.toUpperCase();
	}

	// Fall back to raw keyCode if no explicit mapping exists.
	return AHK_KEY_NAMES[keyCode] ?? keyCode;
}

function toModifierSymbols(modifiers: string[] | undefined): string {
	const symbols = new Set<string>();

	for (const modifier of modifiers ?? []) {
		const symbol = MODIFIER_SYMBOLS[modifier];
		if (symbol) {
			symbols.add(symbol);
		}
	}

	// Emit modifiers in stable order to avoid unnecessary diffs.
	return ["^", "!", "+", "#"].filter((symbol) => symbols.has(symbol)).join("");
}

function quoteAhkKeyForSend(key: string): string {
	// Simple alphanumerics can be sent directly.
	if (/^[a-z0-9]$/i.test(key)) {
		return key;
	}

	// Named keys must be wrapped for AHK's Send syntax.
	return `{${key}}`;
}

function toAhkLine(manipulator: Manipulator): string | null {
	// This converter intentionally focuses on straightforward remaps.
	if (manipulator.type !== "basic") {
		return null;
	}

	// Conditional chains do not map cleanly to static AHK hotkeys.
	if ((manipulator.conditions?.length ?? 0) > 0) {
		return null;
	}

	// Skip delayed/tap-hold behaviors.
	if (
		manipulator.to_delayed_action ||
		(manipulator.to_if_alone?.length ?? 0) > 0
	) {
		return null;
	}

	const fromKeyCode = manipulator.from?.key_code;
	if (!fromKeyCode) {
		return null;
	}

	const firstTo = manipulator.to?.[0];
	// Only the first target key event is used for deterministic one-line output.
	if (!firstTo?.key_code || firstTo.set_variable) {
		return null;
	}

	const fromModifiers = toModifierSymbols(
		manipulator.from?.modifiers?.mandatory,
	);
	const fromKey = normalizeAhkKey(fromKeyCode);

	const toModifiers = toModifierSymbols(firstTo.modifiers);
	const toKey = normalizeAhkKey(firstTo.key_code);
	const sendKey = quoteAhkKeyForSend(toKey);

	return `${fromModifiers}${fromKey}::Send("${toModifiers}${sendKey}")`;
}

function buildGeneratedBlock(lines: string[]): string {
	const body = [
		BEGIN_MARKER,
		"; DO NOT EDIT INSIDE THIS BLOCK",
		"; Run: npm run win:sync-hotkeys",
		"; Source: karabiner/karabiner.json (selected profile, enabled rules only)",
		"; Unsupported mappings are skipped and counted in script output",
		`; Generated by ahk/karabiner-to-ahk.ts at ${new Date().toISOString()}`,
		...lines,
		END_MARKER,
	];

	return body.join("\n");
}

function upsertManagedBlock(
	existing: string | null,
	generatedBlock: string,
): string {
	// Template is used when the output file does not exist yet.
	const template = [
		"#Requires AutoHotkey v2.0",
		"; This file is partially generated from karabiner/karabiner.json.",
		"; Add custom hotkeys outside the managed block below.",
		"",
		generatedBlock,
		"",
	].join("\n");

	if (!existing) {
		return template;
	}

	// Replace only the managed block, preserving custom user content elsewhere.
	const blockPattern = new RegExp(
		`${BEGIN_MARKER}[\\s\\S]*?${END_MARKER}`,
		"m",
	);

	if (blockPattern.test(existing)) {
		return existing.replace(blockPattern, generatedBlock);
	}

	// If markers are missing, append a fresh managed block to the file.
	const trimmed = existing.trimEnd();
	return `${trimmed}\n\n${generatedBlock}\n`;
}

async function main() {
	// 1) Read source config.
	const rawConfig = await readFile(KARABINER_PATH, "utf8");
	const config = readKarabinerConfig(rawConfig);
	const profile = getSelectedProfile(config);

	if (!profile) {
		throw new Error("No Karabiner profile found.");
	}

	const rules = profile.complex_modifications?.rules ?? [];
	const generatedLines: string[] = [];
	let skippedCount = 0;

	// 2) Convert manipulators from enabled rules into AHK hotkey lines.
	for (const rule of rules) {
		if (rule.enabled === false) {
			continue;
		}

		for (const manipulator of rule.manipulators ?? []) {
			const line = toAhkLine(manipulator);
			if (line) {
				generatedLines.push(line);
			} else {
				skippedCount += 1;
			}
		}
	}

	// 3) De-duplicate + sort so generated output is stable across runs.
	const uniqueSortedLines = [...new Set(generatedLines)].sort((a, b) =>
		a.localeCompare(b),
	);

	const generatedBlock = buildGeneratedBlock(uniqueSortedLines);

	// 4) Ensure output directory exists before writing file.
	await mkdir(path.dirname(AHK_PATH), { recursive: true });

	let existing: string | null = null;
	try {
		existing = await readFile(AHK_PATH, "utf8");
	} catch {
		existing = null;
	}

	const nextContent = upsertManagedBlock(existing, generatedBlock);
	await writeFile(AHK_PATH, nextContent, "utf8");

	// 5) Print concise generation stats for install/setup scripts.
	console.log(`Updated ${path.relative(ROOT_DIR, AHK_PATH)}`);
	console.log(`Generated ${uniqueSortedLines.length} hotkeys`);
	console.log(`Skipped ${skippedCount} non-translatable manipulators`);
}

main().catch((error) => {
	const message = error instanceof Error ? error.message : String(error);
	console.error(message);
	process.exit(1);
});
