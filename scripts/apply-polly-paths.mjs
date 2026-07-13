import { readdir, readFile, writeFile } from 'node:fs/promises'
import { join } from 'node:path'

const targetDir = process.argv[2]
if (!targetDir) {
  console.error('Usage: node scripts/apply-polly-paths.mjs <directory>')
  process.exit(1)
}

const BASE = '/marcelloguida-polly'
const SITE = 'https://marcelloguida00.github.io/marcelloguida-polly'

const replacements = [
  [/https:\/\/polly-app\.example\.com\/assets\//g, `${SITE}/assets/`],
  [/https:\/\/polly-app\.example\.com\/support/g, `${SITE}/supportPolly.html`],
  [/https:\/\/polly-app\.example\.com\/privacy/g, `${SITE}/privacyPolly.html`],
  [/https:\/\/polly-app\.example\.com\/data-management/g, `${SITE}/data-managementPolly.html`],
  [/https:\/\/polly-app\.example\.com\//g, `${SITE}/indexPolly.html`],
  [/https:\/\/polly-app\.example\.com/g, `${SITE}/indexPolly.html`],
  [/data-management(?<!Polly)\.html/g, 'data-managementPolly.html'],
  [/support(?<!Polly)\.html/g, 'supportPolly.html'],
  [/privacy(?<!Polly)\.html/g, 'privacyPolly.html'],
  [/404(?<!Polly)\.html/g, '404Polly.html'],
  [/index(?<!Polly)\.html/g, 'indexPolly.html'],
  [/"start_url": "\/marcelloguida-polly\/"/g, `"start_url": "${BASE}/indexPolly.html"`],
  [/href="\/marcelloguida-polly\/"/g, `href="${BASE}/indexPolly.html"`],
  [
    /https:\/\/marcelloguida00\.github\.io\/marcelloguida-polly\/"/g,
    `${SITE}/indexPolly.html"`,
  ],
  [
    /<loc>https:\/\/marcelloguida00\.github\.io\/marcelloguida-polly\/<\/loc>/g,
    `<loc>${SITE}/indexPolly.html</loc>`,
  ],
  [/href="\/(?!marcelloguida-polly)/g, `href="${BASE}/`],
  [/src="\/(?!marcelloguida-polly)/g, `src="${BASE}/`],
  [/"start_url": "\/"/g, `"start_url": "${BASE}/indexPolly.html"`],
  [/"src": "\/assets\//g, `"src": "${BASE}/assets/`],
  [/href="\/marcelloguida-polly\/">Portfolio/g, 'href="/">Portfolio'],
]

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true })
  for (const entry of entries) {
    const path = join(dir, entry.name)
    if (entry.isDirectory()) {
      await walk(path)
      continue
    }
    if (!/\.(html?|css|js|json|xml|txt|webmanifest|toml|md)$/i.test(entry.name)) continue

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
