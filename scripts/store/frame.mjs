// Lays each raw screen under its headline, at 1320 x 2868. Fonts and the screen are embedded as data.
import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const data = async (file, type) => `data:${type};base64,${(await readFile(file)).toString('base64')}`;

export async function frame(browser, scenes, out) {
  const serif = await data(resolve('assets/fonts/Newsreader-SemiBold.ttf'), 'font/ttf');
  const sans = await data(resolve('assets/fonts/PlusJakartaSans-Medium.ttf'), 'font/ttf');
  for (const [i, s] of scenes.entries()) {
    const shot = await data(join(out, 'raw', `${s.name}.png`), 'image/png');
    const ctx = await browser.newContext({ viewport: { width: 1320, height: 2868 }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    const deep = i % 2 === 1;
    await page.setContent(`<!doctype html><html><head><style>
      @font-face{font-family:Serif;src:url(${serif})}
      @font-face{font-family:Sans;src:url(${sans})}
      html,body{margin:0;width:1320px;height:2868px;overflow:hidden}
      body{background:${deep ? 'linear-gradient(165deg,#0b4f75,#072a40)' : 'linear-gradient(165deg,#1288b8,#0b4f75)'};display:flex;flex-direction:column;align-items:center}
      h1{font-family:Serif;font-weight:normal;color:#fff;font-size:112px;line-height:1.05;letter-spacing:-2px;text-align:center;margin:190px 100px 0}
      p{font-family:Sans;color:rgba(255,255,255,.88);font-size:48px;line-height:1.35;text-align:center;margin:40px 130px 0}
      .phone{margin-top:90px;width:930px;height:2021px;border-radius:88px;overflow:hidden;box-shadow:0 50px 140px rgba(0,0,0,.4);outline:16px solid rgba(255,255,255,.16)}
      .phone img{width:100%;display:block}
    </style></head><body><h1>${s.title}</h1><p>${s.sub}</p><div class="phone"><img src="${shot}"></div></body></html>`, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(300);
    await page.screenshot({ path: join(out, `${s.name}.png`) });
    await ctx.close();
  }
}
