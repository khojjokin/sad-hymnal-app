// App Store pictures from the real app: serves the web build, opens each screen in a phone-sized
// Chromium at 3x (so 1320 x 2868, Apple's 6.9-inch size), then lays each one under a headline.
// Usage: node scripts/store/shoot.mjs <web build dir> <out dir>
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { chromium } from 'playwright';
import { frame } from './frame.mjs';

if (process.argv[2] === '--frame-only') {
  const { SCENES: list } = await import('./scenes.mjs');
  const b = await chromium.launch();
  await frame(b, list, resolve(process.argv[3]));
  await b.close();
  process.exit(0);
}

const [, , distArg = 'web-dist', outArg = 'store-out'] = process.argv;
const dist = resolve(distArg);
const out = resolve(outArg);
await mkdir(join(out, 'raw'), { recursive: true });

const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg', '.ttf': 'font/ttf', '.svg': 'image/svg+xml', '.ico': 'image/x-icon' };
const server = createServer(async (req, res) => {
  const path = decodeURIComponent((req.url || '/').split('?')[0]);
  let file = join(dist, path);
  // One page for every route: the app finds its screen from the address.
  if (!existsSync(file) || path.endsWith('/')) file = join(dist, 'index.html');
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'content-type': TYPES[extname(file)] || 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404).end();
  }
}).listen(4173);

const W = 440;
const H = 956;
const favourites = [530, 108, 73, 50, 462, 250, 1, 214];
const recent = [530, 108, 73, 462, 1, 50];

import { SCENES } from './scenes.mjs';

const browser = await chromium.launch();
for (const s of SCENES) {
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 3, colorScheme: s.theme === 'dark' ? 'dark' : 'light', isMobile: true, hasTouch: true });
  await ctx.addInitScript(({ prefs }) => {
    try {
      localStorage.setItem('sdahymnal.prefs.v2', JSON.stringify(prefs));
    } catch {}
  }, { prefs: { theme: s.theme, language: 'en', textSize: 21, favourites, recent } });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.log(`[${s.name}] page error: ${e.message}`));
  await page.goto(`http://localhost:4173${s.path}`, { waitUntil: 'networkidle' });
  // The opening screen fades away and the photos load.
  await page.waitForTimeout(4500);
  if (s.scroll) {
    await page.mouse.move(W / 2, H / 2);
    await page.mouse.wheel(0, s.scroll);
    await page.waitForTimeout(1500);
  }
  await page.screenshot({ path: join(out, 'raw', `${s.name}.png`) });
  await ctx.close();
  console.log(`shot ${s.name}`);
}

// The framed pictures: sea blue, the headline in the app's serif, the screen below with rounded corners.
// Everything is embedded in the page, which a page built in memory can't load from files.
await frame(browser, SCENES, out);
await browser.close();
server.close();
await writeFile(join(out, 'README.txt'), 'App Store screenshots, 1320 x 2868 (iPhone 6.9-inch). raw/ holds the plain screens.\n');
console.log('done');
