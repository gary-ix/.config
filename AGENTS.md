# Repository Agent Rules

This repository uses `AGENTS.md` files to document conventions and workflows for AI agents working on the codebase.

## Workflow

1. **Always keep `AGENTS.md` files up-to-date.** If you add new conventions, helpers, or directories, document them in the relevant `AGENTS.md`.
2. **Whitelist new files in `.gitignore`.** The root `.gitignore` ignores everything by default (`*` on line 2). Any new file or directory that should be tracked must be explicitly whitelisted with a `!` pattern so it is not accidentally committed.

## Directory-Specific Rules

- [`scripts/AGENTS.md`](scripts/AGENTS.md) — macOS installation scripts, shared shell helpers, and conventions
