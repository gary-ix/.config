#!/usr/bin/env bash
set -euo pipefail

CURSOR_GIT_BUNDLE="/Applications/Cursor.app/Contents/Resources/app/extensions/git/dist/main.js"
BACKUP_PATH="${CURSOR_GIT_BUNDLE}.bak"

if [[ ! -f "$CURSOR_GIT_BUNDLE" ]]; then
  echo "Cursor git bundle not found: $CURSOR_GIT_BUNDLE" >&2
  exit 1
fi

export CURSOR_GIT_BUNDLE
export BACKUP_PATH

node <<'EOF'
const fs = require('fs');

const bundlePath = process.env.CURSOR_GIT_BUNDLE;
const backupPath = process.env.BACKUP_PATH;

const readonlySnippet = 'r.workspace.registerFileSystemProvider("git",this,{isReadonly:!0,isCaseSensitive:!0})';
const writableSnippet = 'r.workspace.registerFileSystemProvider("git",this,{isReadonly:!1,isCaseSensitive:!0})';
const writeStub = 'writeFile(){throw new Error("Method not implemented.")}';
const writePatch = 'async writeFile(e,t){await this.model.isInitialized;const{ref:i,submoduleOf:n}=(0,a.fromGitUri)(e);if(""===i){const o=this.model.getRepository(n?r.Uri.file(n):e);if(!o)throw r.FileSystemError.FileNotFound();n||this.cache.set(e.toString(),{uri:e,timestamp:(new Date).getTime()});await o.stage(e,t)}}';

const original = fs.readFileSync(bundlePath, 'utf8');

if (original.includes(writableSnippet) && original.includes(writePatch)) {
  console.log('Cursor staged-edit patch already applied.');
  process.exit(0);
}

if (!original.includes(readonlySnippet)) {
  throw new Error('Readonly provider snippet not found; Cursor may have changed internals.');
}

if (!original.includes(writeStub)) {
  throw new Error('writeFile stub not found; Cursor may have changed internals.');
}

if (!fs.existsSync(backupPath)) {
  fs.copyFileSync(bundlePath, backupPath);
}

const patched = original
  .replace(readonlySnippet, writableSnippet)
  .replace(writeStub, writePatch);

fs.writeFileSync(bundlePath, patched);
console.log(`Patched ${bundlePath}`);
console.log(`Backup: ${backupPath}`);
EOF

echo "Restart Cursor to pick up the change."
