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
  /** The app's green: buttons, switches, the tab bar's pill. */
  accent: string;
  /** The same green where it sits as text or a small icon, tuned to read on this background. */
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
  bg: '#0b1014',
  bg2: '#131920',
  surface: '#1b222a',
  surface2: '#272e38',
  line: '#232a33',
  fg: '#f3f5f7',
  fg2: '#a4adb9',
  fg3: '#87919d',
  accent: '#1fbf5a',
  accent2: '#4fe08a',
  onAccent: '#ffffff',
  accentSoft: 'rgba(31,191,90,0.14)',
  like: '#ff3040',
  danger: '#ff4d4f',
  glass: 'rgba(40,46,55,0.78)',
  blurTint: 'dark',
  hairline: 'rgba(255,255,255,0.09)',
  press: 'rgba(255,255,255,0.05)',
  scrim: 'rgba(0,0,0,0.32)',
  sheet: '#191b1f',
  field: '#24292e',
  round: '#25282b',
  statusBar: 'light',
};

const WHITE_PALETTE: Palette = {
  bg: '#ffffff',
  bg2: '#f5f6f7',
  surface: '#f0f2f4',
  surface2: '#e4e7eb',
  line: '#e3e6ea',
  fg: '#0f1419',
  fg2: '#57606a',
  fg3: '#666e77',
  accent: '#16a34a',
  accent2: '#11823b',
  onAccent: '#ffffff',
  accentSoft: 'rgba(22,163,74,0.12)',
  like: '#ed2939',
  danger: '#e0262e',
  glass: 'rgba(255,255,255,0.82)',
  blurTint: 'light',
  hairline: 'rgba(0,0,0,0.08)',
  press: 'rgba(0,0,0,0.05)',
  scrim: 'rgba(0,0,0,0.22)',
  sheet: '#ffffff',
  field: '#eff1f3',
  round: '#eef0f2',
  statusBar: 'dark',
};

export const PALETTES: Record<ThemeName, Palette> = { dark: DARK_PALETTE, white: WHITE_PALETTE };

/** The colours in use now. Read at render time; see the note at the top of this file. */
export const C: Palette = { ...WHITE_PALETTE };

let current: ThemeName = 'white';

export function themeName(): ThemeName {
  return current;
}

/** Switches every colour in `C` to the theme's. The caller draws the app again afterwards. */
export function applyTheme(name: ThemeName) {
  current = name;
  Object.assign(C, PALETTES[name]);
}
