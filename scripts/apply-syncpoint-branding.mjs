import { readdir, readFile, writeFile } from 'node:fs/promises'
import { join } from 'node:path'

const targetDir = process.argv[2]
if (!targetDir) {
  console.error('Usage: node scripts/apply-syncpoint-branding.mjs <directory>')
  process.exit(1)
}

const replacements = [
  [/SetPoint/g, 'SyncPoint'],
  [/SETPOINT/g, 'SyncPoint'],
  [/setpoint/g, 'syncpoint'],
]

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true })
  for (const entry of entries) {
    const path = join(dir, entry.name)
    if (entry.isDirectory()) {
      await walk(path)
      continue
    }
    if (!/\.(html?|css|js|json|md|txt|xml)$/i.test(entry.name)) continue

    let content = await readFile(path, 'utf8')
    let updated = content
    for (const [pattern, value] of replacements) {
      updated = updated.replace(pattern, value)
    }
    if (updated !== content) {
      await writeFile(path, updated, 'utf8')
    }
  }
}

await walk(targetDir)
