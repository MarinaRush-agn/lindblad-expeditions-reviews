// screenshot.mjs — screenshot a localhost URL with Puppeteer.
// Usage: node screenshot.mjs http://localhost:3000[/path] [label] [width] [height]
// Saves to ./temporary screenshots/screenshot-N[-label].png, auto-incrementing, never overwriting.
import puppeteer from 'puppeteer';
import { mkdir, readdir } from 'node:fs/promises';

const url = process.argv[2];
const label = process.argv[3] || '';
const width = parseInt(process.argv[4] || '1440', 10);
const height = parseInt(process.argv[5] || '900', 10);

if (!url || !url.startsWith('http://localhost')) {
  console.error('Usage: node screenshot.mjs http://localhost:3000[/path] [label] [width] [height]');
  console.error('Refusing non-localhost URLs — always screenshot from a served page, never file://.');
  process.exit(1);
}

const DIR = './temporary screenshots';
await mkdir(DIR, { recursive: true });

const existing = await readdir(DIR);
let n = 1;
for (const f of existing) {
  const m = f.match(/^screenshot-(\d+)/);
  if (m) n = Math.max(n, parseInt(m[1], 10) + 1);
}
const filename = `${DIR}/screenshot-${n}${label ? '-' + label : ''}.png`;

const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.setViewport({ width, height });
await page.goto(url, { waitUntil: 'networkidle0' });
await page.screenshot({ path: filename, fullPage: true });
await browser.close();

console.log(`Saved: ${filename}`);
