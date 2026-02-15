import { PATHS } from "../paths"
import type { CreateInstallModule, ThemeTokens, Variant } from "../types"
import { deriveTerminalAnsi, installFile, readJsonc, writeJson } from "../utils"

function updateVscodeTheme(theme: any, variant: Variant, modeLabel: string) {
  const output = JSON.parse(JSON.stringify(theme))
  output.name = modeLabel
  output.colors = output.colors || {}
  const terminalAnsi = deriveTerminalAnsi(variant);

  const blueHighlight = `${terminalAnsi.blue}14`
  const blueHighlightStrong = `${terminalAnsi.blue}1F`
  const blueHighlightSoft = `${terminalAnsi.blue}10`
  const blueHighlightBorder = `${terminalAnsi.blue}38`

  output.colors["editor.background"] = variant.background
  output.colors["editor.foreground"] = variant.foreground
  output.colors["editorCursor.foreground"] = variant.cursor
  output.colors["selection.background"] = blueHighlight
  output.colors["editor.selectionBackground"] = blueHighlightStrong
  output.colors["editor.inactiveSelectionBackground"] = blueHighlight
  output.colors["editor.selectionHighlightBackground"] = blueHighlight
  output.colors["editor.selectionHighlightBorder"] = blueHighlightBorder
  output.colors["editor.wordHighlightBackground"] = blueHighlight
  output.colors["editor.wordHighlightStrongBackground"] = blueHighlightStrong
  output.colors["editor.wordHighlightBorder"] = blueHighlightBorder
  output.colors["editor.wordHighlightStrongBorder"] = blueHighlightBorder
  output.colors["editor.findMatchBorder"] = blueHighlightBorder
  output.colors["editor.findMatchHighlightBorder"] = blueHighlightBorder
  output.colors["editor.rangeHighlightBorder"] = blueHighlightBorder
  output.colors["editor.hoverHighlightBackground"] = blueHighlightSoft
  output.colors["editor.findRangeHighlightBackground"] = blueHighlightSoft
  output.colors["editor.lineHighlightBackground"] = blueHighlightSoft
  output.colors["errorForeground"] = variant.error
  output.colors["editorError.foreground"] = variant.error
  output.colors["editorWarning.foreground"] = variant.borderActive
  output.colors["editorInfo.foreground"] = variant.info
  output.colors["editorHint.foreground"] = variant.success
  output.colors["terminal.background"] = variant.background
  output.colors["terminal.foreground"] = variant.foreground
  output.colors["terminal.ansiBlack"] = terminalAnsi.black
  output.colors["terminal.ansiRed"] = terminalAnsi.red
  output.colors["terminal.ansiGreen"] = terminalAnsi.green
  output.colors["terminal.ansiYellow"] = terminalAnsi.yellow
  output.colors["terminal.ansiBlue"] = terminalAnsi.blue
  output.colors["terminal.ansiMagenta"] = terminalAnsi.magenta
  output.colors["terminal.ansiCyan"] = terminalAnsi.cyan
  output.colors["terminal.ansiWhite"] = terminalAnsi.white
  output.colors["terminal.ansiBrightBlack"] = terminalAnsi.brightBlack
  output.colors["terminal.ansiBrightRed"] = terminalAnsi.brightRed
  output.colors["terminal.ansiBrightGreen"] = terminalAnsi.brightGreen
  output.colors["terminal.ansiBrightYellow"] = terminalAnsi.brightYellow
  output.colors["terminal.ansiBrightBlue"] = terminalAnsi.brightBlue
  output.colors["terminal.ansiBrightMagenta"] = terminalAnsi.brightMagenta
  output.colors["terminal.ansiBrightCyan"] = terminalAnsi.brightCyan
  output.colors["terminal.ansiBrightWhite"] = terminalAnsi.brightWhite

  return output
}

export const vscodeApp: CreateInstallModule = {
  appName: "vscode",
  async create(tokens: ThemeTokens) {
    const darkSource = await readJsonc<any>(PATHS.templates.vscode.dark)
    const lightSource = await readJsonc<any>(PATHS.templates.vscode.light)

    const darkTheme = updateVscodeTheme(darkSource, tokens.variants.dark, "gtheme-dark")
    const lightTheme = updateVscodeTheme(lightSource, tokens.variants.light, "gtheme-light")

    await writeJson(PATHS.output.vscode.dark, darkTheme)
    await writeJson(PATHS.output.vscode.light, lightTheme)

    return [PATHS.output.vscode.dark, PATHS.output.vscode.light]
  },
  async install() {
    await installFile(PATHS.output.vscode.dark, PATHS.install.vscode.dark)
    await installFile(PATHS.output.vscode.light, PATHS.install.vscode.light)
    return [PATHS.install.vscode.dark, PATHS.install.vscode.light]
  },
}
