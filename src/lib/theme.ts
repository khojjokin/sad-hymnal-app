/*
 * The app's colours: the same two themes as the SDA app, Dark and White.
 *
 * `C` is one object whose values are swapped when the theme changes (applyTheme), and the app is then
 * drawn again from the top, so every screen must read `C.x` while it renders — never copy a colour
 * into a module-level constant.
 */
export type ThemeName = 'dark' | 'white';

type Palette = {
  bg: string;
  bg2: string;
  surface: string;
  surface2: string;
  line: string;
  fg: string;
  fg2: string;
  fg3: string;
  /** The app's sea blue: buttons, switches, the tab bar's pill. */
  accent: string;
  /** The same blue where it sits as text or a small icon, tuned to read on this background. */
  accent2: string;
  onAccent: string;
  accentSoft: string;
  like: string;
  danger: string;
  /** The frosted tab bar, over a blur of this tint. */
  glass: string;
  blurTint: 'dark' | 'light';
  hairline: string;
  press: string;
  scrim: string;
  sheet: string;
  /** Search fields and the thick bands between settings sections. */
  field: string;
  /** Round buttons in screen headers. */
  round: string;
  statusBar: 'light' | 'dark';
};

const DARK_PALETTE: Palette = {
  bg: '#0a1016',
  bg2: '#111a22',
  surface: '#16212b',
  surface2: '#223040',
  line: '#1f2b36',
  fg: '#f3f5f7',
  fg2: '#a4adb9',
  fg3: '#87919d',
  accent: '#0f7bb0',
  accent2: '#5cc2ee',
  onAccent: '#ffffff',
  accentSoft: 'rgba(16,128,181,0.2)',
  like: '#ff3040',
  danger: '#ff4d4f',
  glass: 'rgba(28,40,52,0.8)',
  blurTint: 'dark',
  hairline: 'rgba(255,255,255,0.09)',
  press: 'rgba(255,255,255,0.05)',
  scrim: 'rgba(0,0,0,0.32)',
  sheet: '#141d26',
  field: '#1c2834',
  round: '#1c2834',
  statusBar: 'light',
};

const WHITE_PALETTE: Palette = {
  bg: '#ffffff',
  bg2: '#f3f7fa',
  surface: '#eef4f8',
  surface2: '#dde8ef',
  line: '#e1e9ef',
  fg: '#0c1a24',
  fg2: '#4f5f6b',
  fg3: '#64737e',
  accent: '#0b7db3',
  accent2: '#086a99',
  onAccent: '#ffffff',
  accentSoft: 'rgba(11,125,179,0.1)',
  like: '#ed2939',
  danger: '#e0262e',
  glass: 'rgba(255,255,255,0.82)',
  blurTint: 'light',
  hairline: 'rgba(0,0,0,0.08)',
  press: 'rgba(0,0,0,0.05)',
  scrim: 'rgba(0,0,0,0.22)',
  sheet: '#ffffff',
  field: '#eef3f7',
  round: '#eef3f7',
  statusBar: 'dark',
};

export const PALETTES: Record<ThemeName, Palette> = { dark: DARK_PALETTE, white: WHITE_PALETTE };

/** The colours in use now. Read at render time; see the note at the top of this file. */
export const C: Palette = { ...WHITE_PALETTE };

/** The sea-blue gradient of the app's feature cards (hymn of the day, the share picture, the icon). */
export const SEA = ['#0b4f75', '#0b6f9f', '#117fb0'] as const;

let current: ThemeName = 'white';

export function themeName(): ThemeName {
  return current;
}

/** Switches every colour in `C` to the theme's. The caller draws the app again afterwards. */
export function applyTheme(name: ThemeName) {
  current = name;
  Object.assign(C, PALETTES[name]);
}
