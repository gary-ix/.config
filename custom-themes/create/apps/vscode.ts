import { PATHS } from "../paths"
import type { CreateInstallModule, ThemeTokens, Variant } from "../types"
import { installFile, readJsonc, writeJson } from "../utils"

function updateVscodeTheme(theme: any, variant: Variant, modeLabel: string) {
  const output = JSON.parse(JSON.stringify(theme))
  output.name = modeLabel
  output.colors = output.colors || {}

  const blueHighlight = `${variant.ansi.blue}14`
  const blueHighlightStrong = `${variant.ansi.blue}1F`
  const blueHighlightSoft = `${variant.ansi.blue}10`
  const blueHighlightBorder = `${variant.ansi.blue}38`

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
  output.colors["terminal.background"] = variant.background
  output.colors["terminal.foreground"] = variant.foreground
  output.colors["terminal.ansiBlack"] = variant.ansi.black
  output.colors["terminal.ansiRed"] = variant.ansi.red
  output.colors["terminal.ansiGreen"] = variant.ansi.green
  output.colors["terminal.ansiYellow"] = variant.ansi.yellow
  output.colors["terminal.ansiBlue"] = variant.ansi.blue
  output.colors["terminal.ansiMagenta"] = variant.ansi.magenta
  output.colors["terminal.ansiCyan"] = variant.ansi.cyan
  output.colors["terminal.ansiWhite"] = variant.ansi.white
  output.colors["terminal.ansiBrightBlack"] = variant.ansi.brightBlack
  output.colors["terminal.ansiBrightRed"] = variant.ansi.brightRed
  output.colors["terminal.ansiBrightGreen"] = variant.ansi.brightGreen
  output.colors["terminal.ansiBrightYellow"] = variant.ansi.brightYellow
  output.colors["terminal.ansiBrightBlue"] = variant.ansi.brightBlue
  output.colors["terminal.ansiBrightMagenta"] = variant.ansi.brightMagenta
  output.colors["terminal.ansiBrightCyan"] = variant.ansi.brightCyan
  output.colors["terminal.ansiBrightWhite"] = variant.ansi.brightWhite

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
