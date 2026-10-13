/*
 * Hymn background colours, the SDA app's page colours: the chat-wallpaper gradients and a few soft
 * solids, with Default (the theme's own background) first. Free for everyone here.
 *
 * Words are drawn straight on the colour, so every stop is softened toward the theme's background
 * (black in Dark, white in White) just as far as it takes for the text to keep its contrast: deep
 * colours in Dark, soft pastels in White. Reading (a hymn's words) asks for a little more.
 */
import type { ThemeName } from './theme';

export type HymnColour = {
  id: string;
  name: string;
  kind: 'gradient' | 'solid';
  /** Dark theme (deep) and White theme (the same hues as pastels). */
  colors: readonly string[];
  light: readonly string[];
};

export const HYMN_COLOURS: readonly HymnColour[] = [
  { id: 'parchment', name: 'Parchment', kind: 'solid', colors: ['#2a2318'], light: ['#f7f0e1'] },
  { id: 'dusk', name: 'Dusk', kind: 'gradient', colors: ['#1a1030', '#0b1014', '#0f2a1e'], light: ['#ece4f7', '#f4f1f6', '#e2f1e8'] },
  { id: 'olive', name: 'Olive grove', kind: 'gradient', colors: ['#0f2a1e', '#13331f', '#0b1014'], light: ['#e2f0e6', '#e9f3e3', '#f3f5f2'] },
  { id: 'sea', name: 'Galilee', kind: 'gradient', colors: ['#0a1f33', '#0b1014', '#0f3340'], light: ['#dfeaf6', '#f1f4f7', '#ddeff2'] },
  { id: 'sand', name: 'Desert sand', kind: 'gradient', colors: ['#3a2a14', '#1b1510', '#0b1014'], light: ['#f6ead7', '#f6f0e8', '#f4f4f2'] },
  { id: 'rose', name: 'Sharon rose', kind: 'gradient', colors: ['#3a1422', '#1b0e14', '#0b1014'], light: ['#f8e1e8', '#f7eef1', '#f4f4f5'] },
  { id: 'royal', name: 'Royal', kind: 'gradient', colors: ['#20123f', '#0b1014', '#132a4f'], light: ['#e6e1f6', '#f1f2f7', '#dfe7f5'] },
  { id: 'mint', name: 'Mint', kind: 'solid', colors: ['#0f3324'], light: ['#e3f3e8'] },
  { id: 'sky', name: 'Sky', kind: 'solid', colors: ['#0e2a45'], light: ['#e2eefa'] },
  { id: 'lilac', name: 'Lilac', kind: 'solid', colors: ['#271d4a'], light: ['#ece6f7'] },
  { id: 'peach', name: 'Peach', kind: 'solid', colors: ['#3d2416'], light: ['#fbe9dc'] },
  { id: 'butter', name: 'Butter', kind: 'solid', colors: ['#332c12'], light: ['#f8f1d8'] },
  { id: 'blush', name: 'Blush', kind: 'solid', colors: ['#3d1628'], light: ['#f9e4ea'] },
];

export const colourById = (id: string | null | undefined): HymnColour | null => (id ? HYMN_COLOURS.find((c) => c.id === id) ?? null : null);

function channels(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  const full = h.length === 3 ? h.split('').map((c) => c + c).join('') : h.slice(0, 6);
  const n = parseInt(full, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

const toHex = (c: [number, number, number]) => '#' + c.map((v) => Math.round(Math.min(255, Math.max(0, v))).toString(16).padStart(2, '0')).join('');

/** WCAG relative luminance, 0 (black) to 1 (white). */
export function luminance(hex: string): number {
  const [r, g, b] = channels(hex).map((v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function veil(hex: string, toward: 'black' | 'white', amount: number): string {
  const end = toward === 'white' ? 255 : 0;
  const c = channels(hex);
  return toHex([c[0] + (end - c[0]) * amount, c[1] + (end - c[1]) * amount, c[2] + (end - c[2]) * amount]);
}

/** How light (White) or dark (Dark) a stop may be, as luminance, for the words on it to stay readable. */
const LIMIT = {
  dark: { page: 0.045, reading: 0.02 },
  white: { page: 0.72, reading: 0.8 },
} as const;

function guard(hex: string, theme: ThemeName, reading: boolean): string {
  const limit = LIMIT[theme][reading ? 'reading' : 'page'];
  const fine = (h: string) => (theme === 'white' ? luminance(h) >= limit : luminance(h) <= limit);
  if (fine(hex)) return hex;
  const toward = theme === 'white' ? 'white' : 'black';
  let lo = 0;
  let hi = 1;
  for (let i = 0; i < 14; i++) {
    const mid = (lo + hi) / 2;
    if (fine(veil(hex, toward, mid))) hi = mid;
    else lo = mid;
  }
  return veil(hex, toward, hi);
}

const cache = new Map<string, string[]>();

/** The colour's stops in this theme, top left to bottom right (a solid is two of the same). */
export function colourStops(colour: HymnColour, theme: ThemeName, reading = false): string[] {
  const key = `${colour.id}|${theme}|${reading ? 1 : 0}`;
  const kept = cache.get(key);
  if (kept) return kept;
  const stops = (theme === 'white' ? [...colour.light] : [...colour.colors]).map((c) => guard(c, theme, reading));
  const out = stops.length === 1 ? [stops[0], stops[0]] : stops;
  cache.set(key, out);
  return out;
}

/** A swatch's stops: the colour as it is, a little brighter in Dark so it shows on the sheet. */
export function swatchStops(colour: HymnColour, theme: ThemeName): string[] {
  const raw = theme === 'white' ? [...colour.light] : colour.colors.map((c) => veil(c, 'white', 0.12));
  return raw.length === 1 ? [raw[0], raw[0]] : raw;
}
