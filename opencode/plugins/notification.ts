import type { Plugin } from "@opencode-ai/plugin"

// const systemNotifications = process.env.OPENCODE_NOTIFY === "1"
const systemNotifications = false

export const NotificationPlugin: Plugin = async ({ $ }) => {
  const playSound = async (sound: string) => {
    await $`afplay /System/Library/Sounds/${sound}.aiff`
  }

  const notify = async (title: string, message: string, sound: string) => {
    await playSound(sound)
    if (systemNotifications) {
      await $`osascript -e ${`display notification "${message}" with title "${title}" sound name "${sound}"`}`
    }
  }

  return {
    event: async ({ event }) => {
      const type = (event as { type: string }).type

      // Session events
      if (type === "session.idle") {
        await notify("OpenCode", "Session completed!", "Glass")
      }
      if (type === "session.error") {
        await notify("OpenCode Error", "Session encountered an error", "Basso")
      }
      // if (type === "session.created") {}
      // if (type === "session.updated") {}
      // if (type === "session.deleted") {}
      // if (type === "session.status") {}
      // if (type === "session.compacted") {}
      // if (type === "session.diff") {}

      // Permission events
      if (type === "permission.asked") {
        await notify("OpenCode", "Permission required", "Submarine")
      }
      // if (type === "permission.replied") {}

      // Question events
      if (type === "question.asked") {
        await notify("OpenCode", "Input required", "Submarine")
      }
      // if (type === "question.replied") {}
      // if (type === "question.rejected") {}

      // Installation events
      // if (type === "installation.updated") {}
      // if (type === "installation.update-available") {}

      // Project events
      // if (type === "project.updated") {}

      // File events
      // if (type === "file.edited") {}
      // if (type === "file.watcher.updated") {}

      // Message events
      // if (type === "message.updated") {}
      // if (type === "message.removed") {}
      // if (type === "message.part.updated") {}
      // if (type === "message.part.removed") {}
      // if (type === "message.part.delta") {}

      // LSP events
      // if (type === "lsp.client.diagnostics") {}
      // if (type === "lsp.updated") {}

      // TUI events
      // if (type === "tui.prompt.append") {}
      // if (type === "tui.command.execute") {}
      // if (type === "tui.toast.show") {}
      // if (type === "tui.session.select") {}

      // Command events
      // if (type === "command.executed") {}

      // Todo events
      // if (type === "todo.updated") {}

      // VCS events
      // if (type === "vcs.branch.updated") {}

      // MCP events
      // if (type === "mcp.tools.changed") {}
      // if (type === "mcp.browser.open.failed") {}

      // PTY events
      // if (type === "pty.created") {}
      // if (type === "pty.updated") {}
      // if (type === "pty.exited") {}
      // if (type === "pty.deleted") {}

      // Server events
      // if (type === "server.connected") {}
      // if (type === "server.instance.disposed") {}

      // Global events
      // if (type === "global.disposed") {}

      // Worktree events
      // if (type === "worktree.ready") {}
      // if (type === "worktree.failed") {}
    },
  }
}
