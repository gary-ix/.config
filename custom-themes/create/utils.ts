import { copyFile, mkdir, readFile, writeFile } from "fs/promises"
import path from "path"
import { parse } from "jsonc-parser"

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
