import { spawnSync } from "node:child_process";

const MBP_SETTINGS = {
	sleep: {
		description: "Sleep timer in minutes (0 = never).",
		normal: 0,
		server: 0,
	},
	displaysleep: {
		description: "Display sleep timer in minutes (0 = never).",
		normal: 0,
		server: 0,
	},
	disksleep: {
		description: "Disk sleep timer in minutes (0 = never).",
		normal: 10,
		server: 10,
	},
	womp: {
		description: "Wake for network access (Wake on Magic Packet): 1 on, 0 off.",
		normal: 1,
		server: 1,
	},
	powernap: {
		description: "Power Nap background tasks while sleeping: 1 on, 0 off.",
		normal: 1,
		server: 1,
	},
	tcpkeepalive: {
		description: "Maintain TCP sessions during sleep: 1 on, 0 off.",
		normal: 1,
		server: 1,
	},
	standby: {
		description: "Enable standby transition after sleep: 1 on, 0 off.",
		normal: 1,
		server: 0,
	},
	ttyskeepawake: {
		description:
			"Prevent sleep when remote tty sessions are active: 1 on, 0 off.",
		normal: 1,
		server: 1,
	},
	hibernatemode: {
		description: "Hibernate mode (0 RAM only, 3 safe sleep, 25 hibernate).",
		normal: 3,
		server: 3,
	},
	lessbright: {
		description: "Slightly dim display on battery: 1 on, 0 off.",
		normal: 1,
		server: 1,
	},
	powermode: {
		description:
			"CPU power profile (0 lower power, 1 balanced, 2 higher performance).",
		normal: 2,
		server: 2,
	},
	lowpowermode: {
		description: "Low power mode (0 off, 1 on).",
		normal: 0,
		server: 0,
	},
	restartPowerFailure: {
		description: "Auto restart after power failure (on/off).",
		normal: "off",
		server: "on",
	},
	restartFreeze: {
		description: "Auto restart after system freeze (on/off).",
		normal: "off",
		server: "on",
	},
} as const;

const RESTART_SETTINGS = {
	restartPowerFailure: ["-getrestartpowerfailure"],
	restartFreeze: ["-getrestartfreeze"],
} as const;

type SettingKey = keyof typeof MBP_SETTINGS;
type ModeKey = "normal" | "server";

type PostCheck = {
	name: string;
	ok: boolean;
	details: string;
	critical?: boolean;
};

const RESTART_SETTERS = {
	restartPowerFailure: ["-setrestartpowerfailure"],
	restartFreeze: ["-setrestartfreeze"],
} as const;

function runCommand(command: string, args: readonly string[]) {
	const result = spawnSync(command, args, {
		encoding: "utf8",
	});

	return {
		success: result.status === 0,
		stdout: (result.stdout ?? "").trimEnd(),
		stderr: (result.stderr ?? "").trimEnd(),
		error: result.error,
	};
}

function getActivePowerSource(): string {
	const result = runCommand("pmset", ["-g", "batt"]);

	if (!result.success) {
		throw new Error(result.stderr || "Unable to read active power source.");
	}

	const match = result.stdout.match(/Now drawing from '([^']+)'/);
	if (!match) {
		throw new Error("Unable to parse active power source from pmset output.");
	}

	return match[1];
}

function parsePmsetCustom(
	output: string,
): Record<string, Record<string, string>> {
	const sections: Record<string, Record<string, string>> = {};
	let currentSection: string | null = null;

	for (const line of output.split("\n")) {
		const sectionHeader = line.match(/^([^:]+):$/);
		if (sectionHeader) {
			currentSection = sectionHeader[1];
			sections[currentSection] = {};
			continue;
		}

		if (!currentSection) {
			continue;
		}

		const trimmed = line.trim();
		if (!trimmed) {
			continue;
		}

		const parts = trimmed.split(/\s+/);
		if (parts.length < 2) {
			continue;
		}

		const [key, ...valueParts] = parts;
		sections[currentSection][key] = valueParts.join(" ");
	}

	return sections;
}

function getCurrentPmsetValues(): {
	activePowerSource: string;
	sections: Record<string, Record<string, string>>;
} {
	const activePowerSource = getActivePowerSource();
	const result = runCommand("pmset", ["-g", "custom"]);

	if (!result.success) {
		throw new Error(result.stderr || "Unable to read pmset custom settings.");
	}

	const sections = parsePmsetCustom(result.stdout);

	if (!sections[activePowerSource]) {
		throw new Error(`Unable to find pmset section for '${activePowerSource}'.`);
	}

	return { activePowerSource, sections };
}

function parsePmsetCapabilities(output: string): Record<string, Set<string>> {
	const capabilitiesBySource: Record<string, Set<string>> = {};
	let currentSource: string | null = null;

	for (const line of output.split("\n")) {
		const headerMatch = line.match(/^Capabilities for (.+):$/);
		if (headerMatch) {
			currentSource = headerMatch[1];
			capabilitiesBySource[currentSource] = new Set<string>();
			continue;
		}

		if (!currentSource) {
			continue;
		}

		const capability = line.trim();
		if (!capability) {
			continue;
		}

		capabilitiesBySource[currentSource].add(capability);
	}

	return capabilitiesBySource;
}

function getPmsetCapabilitiesForSource(powerSource: string): Set<string> {
	const result = runCommand("pmset", ["-g", "cap"]);
	if (!result.success) {
		throw new Error(result.stderr || "Unable to read pmset capabilities.");
	}

	const capabilitiesBySource = parsePmsetCapabilities(result.stdout);
	return capabilitiesBySource[powerSource] ?? new Set<string>();
}

function getPowerSourceFlag(powerSource: string): "-c" | "-b" | "-u" {
	if (powerSource === "AC Power") {
		return "-c";
	}

	if (powerSource === "Battery Power") {
		return "-b";
	}

	if (powerSource === "UPS Power") {
		return "-u";
	}

	throw new Error(`Unsupported power source '${powerSource}'.`);
}

function parseRestartSetting(output: string): "on" | "off" | null {
	const match = output.match(/:\s*(on|off)\s*$/i);
	if (!match) {
		return null;
	}

	return match[1].toLowerCase() as "on" | "off";
}

function getRestartSetting(key: keyof typeof RESTART_SETTINGS): string {
	const result = runCommand("systemsetup", RESTART_SETTINGS[key]);
	const combinedOutput = `${result.stdout}\n${result.stderr}`.toLowerCase();

	if (combinedOutput.includes("administrator access")) {
		return "unavailable (requires sudo)";
	}

	if (!result.success) {
		return "unavailable";
	}

	return parseRestartSetting(result.stdout) ?? "unknown";
}

function formatValue(value: string): string {
	if (/^-?\d+$/.test(value)) {
		return String(Number(value));
	}

	return value;
}

function requireSudoForModeChange() {
	if (typeof process.getuid === "function" && process.getuid() !== 0) {
		throw new Error(
			"Mode changes require sudo. Run with: sudo npm run mac:power:<mode>",
		);
	}
}

function applyPmsetMode(mode: ModeKey) {
	const activePowerSource = getActivePowerSource();
	const powerSourceFlag = getPowerSourceFlag(activePowerSource);
	const capabilities = getPmsetCapabilitiesForSource(activePowerSource);
	const args: string[] = [powerSourceFlag];

	for (const key of Object.keys(MBP_SETTINGS) as SettingKey[]) {
		if (key in RESTART_SETTINGS) {
			continue;
		}

		if (!capabilities.has(key)) {
			continue;
		}

		args.push(key, String(MBP_SETTINGS[key][mode]));
	}

	const result = runCommand("pmset", args);
	if (!result.success) {
		throw new Error(result.stderr || "Unable to apply pmset settings.");
	}
}

function applyRestartMode(mode: ModeKey): string[] {
	const skipped: string[] = [];

	for (const key of Object.keys(RESTART_SETTERS) as Array<
		keyof typeof RESTART_SETTERS
	>) {
		const result = runCommand("systemsetup", [
			...RESTART_SETTERS[key],
			String(MBP_SETTINGS[key][mode]),
		]);

		if (!result.success) {
			const output = `${result.stdout}\n${result.stderr}`.toLowerCase();
			if (output.includes("administrator access")) {
				throw new Error(
					"Mode changes require sudo for systemsetup restart settings.",
				);
			}

			if (
				output.includes("not supported") ||
				output.includes("not available") ||
				output.includes("unsupported") ||
				output.includes("error:-99")
			) {
				skipped.push(key);
				continue;
			}

			throw new Error(
				`${result.stdout}\n${result.stderr}`.trim() ||
					`Unable to apply restart setting '${key}' via systemsetup.`,
			);
		}
	}

	return skipped;
}

function applyConfig(mode: ModeKey) {
	requireSudoForModeChange();
	console.log(`Applying '${mode}' mode...`);
	applyPmsetMode(mode);
	const skippedRestartSettings = applyRestartMode(mode);

	if (skippedRestartSettings.length > 0) {
		console.warn(
			`Skipped unsupported restart settings: ${skippedRestartSettings.join(", ")}`,
		);
	}

	if (mode === "server") {
		runServerPostChecks();
	}

	console.log(`Applied '${mode}' mode.`);
}

function parseOnOffValue(output: string): "on" | "off" | null {
	const match = output.match(/\b(on|off)\b/i);
	if (!match) {
		return null;
	}

	return match[1].toLowerCase() as "on" | "off";
}

function isMissingCommandError(error: unknown): boolean {
	if (typeof error !== "object" || error === null) {
		return false;
	}

	if (!("code" in error)) {
		return false;
	}

	return (error as { code?: string }).code === "ENOENT";
}

function checkScreenSharingEnabled(): PostCheck {
	const result = runCommand("launchctl", [
		"print",
		"system/com.apple.screensharing",
	]);
	if (!result.success) {
		return {
			name: "Screen Sharing (VNC)",
			ok: false,
			details:
				"Screen Sharing is off. Enable it in System Settings > General > Sharing.",
			critical: true,
		};
	}

	return {
		name: "Screen Sharing (VNC)",
		ok: true,
		details: "Screen Sharing service is enabled.",
		critical: true,
	};
}

function checkTailscaleConnected(): PostCheck {
	const tailscaleCommands = [
		"tailscale",
		"/Applications/Tailscale.app/Contents/MacOS/Tailscale",
	];

	for (const command of tailscaleCommands) {
		const result = runCommand(command, ["status", "--json"]);

		if (isMissingCommandError(result.error)) {
			continue;
		}

		if (!result.success) {
			return {
				name: "Tailscale",
				ok: false,
				details: (
					result.stderr ||
					result.stdout ||
					"Unable to read Tailscale status."
				).trim(),
				critical: true,
			};
		}

		try {
			const status = JSON.parse(result.stdout) as {
				BackendState?: string;
				Self?: {
					Online?: boolean;
					DNSName?: string;
					TailscaleIPs?: string[];
				};
			};

			const online = status.BackendState === "Running" && status.Self?.Online;
			if (online) {
				const dnsName = status.Self?.DNSName || "unknown host";
				const ip = status.Self?.TailscaleIPs?.[0] || "no Tailscale IP";
				return {
					name: "Tailscale",
					ok: true,
					details: `Connected as ${dnsName} (${ip}).`,
					critical: true,
				};
			}

			return {
				name: "Tailscale",
				ok: false,
				details: `Tailscale is not connected (state: ${status.BackendState ?? "unknown"}).`,
				critical: true,
			};
		} catch {
			return {
				name: "Tailscale",
				ok: false,
				details: "Unable to parse Tailscale status output.",
				critical: true,
			};
		}
	}

	return {
		name: "Tailscale",
		ok: false,
		details: "Tailscale CLI not found. Install the Tailscale app and sign in.",
		critical: true,
	};
}

function checkServerPmsetTargets(): PostCheck {
	const { activePowerSource, sections } = getCurrentPmsetValues();
	const capabilities = getPmsetCapabilitiesForSource(activePowerSource);
	const keysToCheck: Array<keyof typeof MBP_SETTINGS> = [
		"sleep",
		"womp",
		"standby",
		"tcpkeepalive",
		"ttyskeepawake",
		"powermode",
		"lowpowermode",
	];
	const supportedKeys = keysToCheck.filter((key) => capabilities.has(key));

	const mismatches: string[] = [];
	const activeSection = sections[activePowerSource] ?? {};

	for (const key of supportedKeys) {
		const expected = String(MBP_SETTINGS[key].server);
		const actual = activeSection[key];

		if (actual === undefined) {
			mismatches.push(
				`${activePowerSource}:${key}=unavailable (expected ${expected})`,
			);
			continue;
		}

		if (formatValue(actual) !== expected) {
			mismatches.push(
				`${activePowerSource}:${key}=${formatValue(actual)} (expected ${expected})`,
			);
		}
	}

	return {
		name: "Server pmset targets",
		ok: mismatches.length === 0,
		details:
			mismatches.length === 0
				? `${supportedKeys.join("/")} match server mode for ${activePowerSource}.`
				: `Mismatches: ${mismatches.join("; ")}`,
		critical: true,
	};
}

function checkRemoteLoginEnabled(): PostCheck {
	const result = runCommand("systemsetup", ["-getremotelogin"]);
	if (!result.success) {
		return {
			name: "SSH remote login",
			ok: false,
			details: result.stderr || "Unable to check Remote Login state.",
		};
	}

	const state = parseOnOffValue(result.stdout);
	return {
		name: "SSH remote login",
		ok: state === "on",
		details:
			state === "on"
				? "Remote Login is on."
				: "Remote Login is off. Enable it for a reliable fallback path.",
		critical: true,
	};
}

function runServerPostChecks() {
	const checks: PostCheck[] = [];

	try {
		const activePowerSource = getActivePowerSource();
		checks.push({
			name: "Power source",
			ok: activePowerSource === "AC Power",
			details:
				activePowerSource === "AC Power"
					? "Running on AC power."
					: `Running on ${activePowerSource}. Use AC for always-on reliability.`,
			critical: true,
		});
	} catch (error) {
		checks.push({
			name: "Power source",
			ok: false,
			details: error instanceof Error ? error.message : String(error),
			critical: true,
		});
	}

	try {
		checks.push(checkServerPmsetTargets());
	} catch (error) {
		checks.push({
			name: "Server pmset targets",
			ok: false,
			details: error instanceof Error ? error.message : String(error),
			critical: true,
		});
	}

	checks.push(checkTailscaleConnected());
	checks.push(checkRemoteLoginEnabled());
	checks.push(checkScreenSharingEnabled());

	console.log("Server mode post-checks:");
	for (const check of checks) {
		const status = check.ok ? "OK" : check.critical ? "FAIL" : "WARN";
		console.log(`- [${status}] ${check.name}: ${check.details}`);
	}

	const criticalFailures = checks.filter(
		(check) => check.critical && !check.ok,
	);
	if (criticalFailures.length > 0) {
		console.warn(
			"Server mode applied, but critical reachability checks failed. Remote access through Tailscale/SSH/Screen Sharing may not work.",
		);
	}
}

function getCurrent() {
	const { activePowerSource, sections } = getCurrentPmsetValues();
	const sectionPriority = [
		activePowerSource,
		...Object.keys(sections).filter((section) => section !== activePowerSource),
	];

	console.log(`Current system settings (${activePowerSource}):`);

	for (const key of Object.keys(MBP_SETTINGS) as SettingKey[]) {
		if (key in RESTART_SETTINGS) {
			console.log(
				`${key}: ${getRestartSetting(key as keyof typeof RESTART_SETTINGS)}`,
			);
			continue;
		}

		const settingValue = sectionPriority
			.map((section) => sections[section][key])
			.find((value) => value !== undefined);

		console.log(
			`${key}: ${settingValue ? formatValue(settingValue) : "unavailable"}`,
		);
	}
}

function main() {
	const mode = process.argv[2];

	if (mode === "current") {
		getCurrent();
		return;
	}

	if (mode === "normal") {
		applyConfig("normal");
		return;
	}

	if (mode === "server") {
		applyConfig("server");
		return;
	}

	console.error(
		"Usage: tsx scripts/mac-only/mac-power-mode.ts <current|normal|server>",
	);
	process.exit(1);
}

try {
	main();
} catch (error) {
	const message = error instanceof Error ? error.message : String(error);
	console.error(message);
	process.exit(1);
}
