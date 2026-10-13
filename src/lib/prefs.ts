import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSyncExternalStore } from 'react';

/*
 * What the app remembers, on the phone only (there is no account): the look, the language, the text
 * size on hymns, favourites and the hymns opened lately. Loaded once before the first screen draws
 * (loadPrefs in the root layout), read with usePrefs(), changed with setPrefs(), saved at once.
 */

export type ThemeChoice = 'system' | 'dark' | 'white';
export type Language = 'en' | 'es' | 'fr' | 'pt' | 'de' | 'sw';
export const LANGUAGES: Language[] = ['en', 'es', 'fr', 'pt', 'de', 'sw'];

export type Prefs = {
  theme: ThemeChoice;
  language: Language;
  textSize: number;
  favourites: number[];
  /** Most recent first. */
  recent: number[];
};

export const DEFAULT_PREFS: Prefs = { theme: 'system', language: 'en', textSize: 20, favourites: [], recent: [] };

export const TEXT_MIN = 15;
export const TEXT_MAX = 32;
const RECENT_MAX = 30;
const KEY = 'sdahymnal.prefs.v2';

let state: Prefs = DEFAULT_PREFS;
const listeners = new Set<() => void>();
const emit = () => listeners.forEach((l) => l());

const hymnList = (v: unknown): number[] => (Array.isArray(v) ? v.filter((n): n is number => Number.isInteger(n) && n >= 1 && n <= 695) : []);

/** Reads what was kept, keeping only values of the right shape so a damaged copy can't break the app. */
export async function loadPrefs(): Promise<Prefs> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    const kept = (raw ? JSON.parse(raw) : {}) as Partial<Prefs>;
    state = {
      theme: kept.theme === 'dark' || kept.theme === 'white' ? kept.theme : 'system',
      language: LANGUAGES.includes(kept.language as Language) ? (kept.language as Language) : 'en',
      textSize: Math.min(TEXT_MAX, Math.max(TEXT_MIN, Math.round(Number(kept.textSize)) || DEFAULT_PREFS.textSize)),
      favourites: hymnList(kept.favourites),
      recent: hymnList(kept.recent),
    };
  } catch {
    state = DEFAULT_PREFS;
  }
  emit();
  return state;
}

export const getPrefs = (): Prefs => state;

export function setPrefs(patch: Partial<Prefs> | ((p: Prefs) => Partial<Prefs>)) {
  state = { ...state, ...(typeof patch === 'function' ? patch(state) : patch) };
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

export function toggleFavourite(n: number) {
  setPrefs((p) => ({ favourites: p.favourites.includes(n) ? p.favourites.filter((x) => x !== n) : [...p.favourites, n] }));
}

/** Puts a hymn at the front of the recently opened list. */
export function noteOpened(n: number) {
  if (state.recent[0] === n) return;
  setPrefs((p) => ({ recent: [n, ...p.recent.filter((x) => x !== n)].slice(0, RECENT_MAX) }));
}
