// App Store pictures from the real app: serves the web build, opens each screen in a phone-sized
// Chromium at 3x (so 1320 x 2868, Apple's 6.9-inch size), then lays each one under a headline.
// Usage: node scripts/store/shoot.mjs <web build dir> <out dir>
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { chromium } from 'playwright';

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

// Each picture: the screen, its look, an optional scroll, and the headline that goes over it.
const SCENES = [
  { name: '01-home', path: '/', theme: 'white', title: 'Every hymn in the SDA Hymnal', sub: 'All 695, numbered as in the book. No signal needed.' },
  { name: '02-hymn', path: '/hymn/530', theme: 'white', title: 'Clear words, made for singing', sub: 'Large type you can size to suit your eyes.' },
  { name: '03-discover', path: '/discover', theme: 'white', title: 'A new hymn every day', sub: 'Hymns for the morning, the evening and the Sabbath.' },
  { name: '04-story', path: '/discover', theme: 'dark', scroll: 900, title: 'The stories behind the hymns', sub: 'Meet the people who wrote them.' },
  { name: '05-dark', path: '/hymn/1', theme: 'dark', title: 'Easy on the eyes', sub: 'Light and dark, for church and for evening worship.' },
  { name: '06-favourites', path: '/favourites', theme: 'white', title: 'Keep your favourites close', sub: 'Tap the heart on any hymn.' },
];

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
const font = (f) => `file://${resolve('assets/fonts', f)}`;
for (const [i, s] of SCENES.entries()) {
  const ctx = await browser.newContext({ viewport: { width: 1320, height: 2868 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  const shot = `file://${join(out, 'raw', `${s.name}.png`)}`;
  const dark = i % 2 === 1;
  await page.setContent(`<!doctype html><html><head><style>
    @font-face{font-family:Serif;src:url(${font('Newsreader-SemiBold.ttf')})}
    @font-face{font-family:Sans;src:url(${font('PlusJakartaSans-Medium.ttf')})}
    html,body{margin:0;width:1320px;height:2868px;overflow:hidden}
    body{background:${dark ? 'linear-gradient(160deg,#0b4f75,#082f47)' : 'linear-gradient(160deg,#117fb0,#0b4f75)'};display:flex;flex-direction:column;align-items:center}
    h1{font-family:Serif;font-weight:normal;color:#fff;font-size:104px;line-height:1.08;letter-spacing:-1.5px;text-align:center;margin:170px 110px 0}
    p{font-family:Sans;color:rgba(255,255,255,.86);font-size:46px;line-height:1.35;text-align:center;margin:36px 140px 0}
    .phone{margin-top:96px;width:1020px;height:2216px;border-radius:96px;overflow:hidden;box-shadow:0 40px 120px rgba(0,0,0,.35);border:14px solid rgba(255,255,255,.14)}
    .phone img{width:100%;display:block}
  </style></head><body><h1>${s.title}</h1><p>${s.sub}</p><div class="phone"><img src="${shot}"></div></body></html>`, { waitUntil: 'load' });
  await page.waitForTimeout(500);
  await page.screenshot({ path: join(out, `${s.name}.png`) });
  await ctx.close();
}
await browser.close();
server.close();
await writeFile(join(out, 'README.txt'), 'App Store screenshots, 1320 x 2868 (iPhone 6.9-inch). raw/ holds the plain screens.\n');
console.log('done');
