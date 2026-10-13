import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSyncExternalStore } from 'react';

/*
 * Everything the app remembers, kept on the phone only (there is no account): the look, how hymns
 * read, the favourites and what was opened lately. One object, loaded once before the first screen
 * draws (loadPrefs in the root layout), read with usePrefs() and changed with setPrefs(), which saves
 * it at once and redraws whatever reads it.
 */

export type ThemeChoice = 'system' | 'dark' | 'white';
export type FontChoice = 'app' | 'serif';
export type Spacing = 'compact' | 'normal' | 'relaxed';

export type Prefs = {
  theme: ThemeChoice;
  /** The colour behind a hymn's words: a PAGE_COLOURS id, or '' for the theme's own background. */
  hymnColour: string;
  /** Behind the hymnal list too, or only behind the words. */
  colourList: boolean;
  textSize: number;
  font: FontChoice;
  spacing: Spacing;
  verseNumbers: boolean;
  /** Sing the refrain after every verse, as a congregation does, instead of printing it once. */
  repeatRefrain: boolean;
  keepAwake: boolean;
  haptics: boolean;
  /** Keep a list of hymns opened lately. */
  history: boolean;
  favourites: number[];
  /** Most recent first. */
  recent: number[];
};

export const DEFAULT_PREFS: Prefs = {
  theme: 'system',
  hymnColour: '',
  colourList: true,
  textSize: 19,
  font: 'serif',
  spacing: 'normal',
  verseNumbers: true,
  repeatRefrain: false,
  keepAwake: true,
  haptics: true,
  history: true,
  favourites: [],
  recent: [],
};

export const TEXT_MIN = 14;
export const TEXT_MAX = 32;
const RECENT_MAX = 60;
const KEY = 'sdahymnal.prefs.v1';

let state: Prefs = DEFAULT_PREFS;
const listeners = new Set<() => void>();

function emit() {
  listeners.forEach((l) => l());
}

/** Reads what was kept, keeping only values of the right shape so an old or damaged copy can't break the app. */
export async function loadPrefs(): Promise<Prefs> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    const kept = raw ? (JSON.parse(raw) as Partial<Prefs>) : {};
    const next: Prefs = { ...DEFAULT_PREFS };
    (Object.keys(DEFAULT_PREFS) as (keyof Prefs)[]).forEach((k) => {
      const v = kept[k];
      const d = DEFAULT_PREFS[k];
      if (Array.isArray(d)) {
        if (Array.isArray(v)) (next as any)[k] = v.filter((n) => Number.isInteger(n) && n >= 1 && n <= 695);
      } else if (typeof v === typeof d) (next as any)[k] = v;
    });
    // Choices with a fixed set of answers: anything else (a damaged copy) falls back to the default.
    if (!['system', 'dark', 'white'].includes(next.theme)) next.theme = DEFAULT_PREFS.theme;
    if (!['app', 'serif'].includes(next.font)) next.font = DEFAULT_PREFS.font;
    if (!['compact', 'normal', 'relaxed'].includes(next.spacing)) next.spacing = DEFAULT_PREFS.spacing;
    next.textSize = Math.min(TEXT_MAX, Math.max(TEXT_MIN, Math.round(next.textSize) || DEFAULT_PREFS.textSize));
    state = next;
  } catch {
    state = DEFAULT_PREFS;
  }
  emit();
  return state;
}

export function getPrefs(): Prefs {
  return state;
}

export function setPrefs(patch: Partial<Prefs> | ((p: Prefs) => Partial<Prefs>)) {
  const change = typeof patch === 'function' ? patch(state) : patch;
  state = { ...state, ...change };
  emit();
  AsyncStorage.setItem(KEY, JSON.stringify(state)).catch(() => {});
}

function subscribe(l: () => void) {
  listeners.add(l);
  return () => {
    listeners.delete(l);
  };
}

export function usePrefs(): Prefs {
  return useSyncExternalStore(subscribe, getPrefs, getPrefs);
}

/* ---------- favourites and history ---------- */

export function toggleFavourite(n: number) {
  setPrefs((p) => ({ favourites: p.favourites.includes(n) ? p.favourites.filter((x) => x !== n) : [...p.favourites, n] }));
}

/** Puts a hymn at the top of the recent list (when history is on). */
export function noteOpened(n: number) {
  if (!state.history) return;
  if (state.recent[0] === n) return;
  setPrefs((p) => ({ recent: [n, ...p.recent.filter((x) => x !== n)].slice(0, RECENT_MAX) }));
}
