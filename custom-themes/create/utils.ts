import { copyFile, mkdir, readFile, writeFile } from "fs/promises"
import path from "path"
import { parse } from "jsonc-parser"
import type { TerminalAnsi, Variant } from "./types"

export async function readJsonc<T>(filePath: string): Promise<T> {
  const content = await readFile(filePath, "utf8")
  return parse(content) as T
}

export async function writeJson(filePath: string, value: unknown): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8")
}

export async function writeText(filePath: string, value: string): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, value, "utf8")
}

export async function installFile(sourcePath: string, destinationPath: string): Promise<void> {
  await mkdir(path.dirname(destinationPath), { recursive: true })
  await copyFile(sourcePath, destinationPath)
}

export function deriveTerminalAnsi(variant: Variant): TerminalAnsi {
  return {
    black: variant.background,
    red: variant.syntax.keyword,
    green: variant.syntax.string,
    yellow: variant.syntax.type,
    blue: variant.syntax.variable,
    magenta: variant.syntax.number,
    cyan: variant.syntax.method,
    white: variant.syntax.punctuation,
    brightBlack: variant.syntax.comment,
    brightRed: variant.syntax.keyword,
    brightGreen: variant.syntax.function,
    brightYellow: variant.syntax.type,
    brightBlue: variant.syntax.variable,
    brightMagenta: variant.syntax.number,
    brightCyan: variant.syntax.function,
    brightWhite: variant.foreground,
  }
}
