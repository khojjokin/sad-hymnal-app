/*
 * The Seventh-day Adventist Hymnal (1985), numbered 1–695 as in the printed book (660–695 are the
 * sentences and responses), so anyone can follow along in church.
 *
 * Everything is bundled with the app (assets/data/hymns.json), so the hymnal opens at once and works
 * with no signal. The words are in the app only for the 502 hymns whose texts are in the public
 * domain; the other 193 (modern texts and translations still under copyright) show their title and
 * author and open the hymn's page on Hymnary.org. The same rule as the SDA app's hymnal.
 */
import data from '../../assets/data/hymns.json';

export type Hymn = {
  number: number;
  title: string;
  section: string;
  author: string;
  /** Verses separated by a blank line; a refrain block starts with "Refrain:". Empty when not shown. */
  lyrics: string;
  publicDomain: boolean;
};

type Raw = { n: number; t: string; s: string; a: string; l: string; pd: boolean };

export const HYMNS: Hymn[] = (data as Raw[]).map((h) => ({ number: h.n, title: h.t, section: h.s, author: h.a, lyrics: h.l, publicDomain: h.pd }));
export const HYMN_COUNT = HYMNS.length;

export const hymnByNumber = (n: number): Hymn | undefined => HYMNS[n - 1];

/** Keeps a hymn number inside the book. */
export function clampHymn(n: number): number {
  return Math.min(HYMN_COUNT, Math.max(1, Math.floor(n) || 1));
}

/** The hymn's page on Hymnary.org, for words the app doesn't show. */
export const hymnaryUrl = (n: number) => `https://hymnary.org/hymn/SDAH1985/${n}`;

/** Lower-case letters, digits and single spaces, so "jesus' love" finds "Jesus' Love". */
export function searchKey(s: string): string {
  return s
    .toLowerCase()
    .replace(/[’']/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Each hymn's search forms, worked out once: the title, and the title with author and first line. */
export const SEARCH_INDEX = HYMNS.map((h) => ({
  hymn: h,
  title: searchKey(h.title),
  all: searchKey(`${h.title} ${h.author} ${h.lyrics.split('\n')[0] ?? ''}`),
}));

export type Verse = { kind: 'verse' | 'refrain'; text: string; number: number };

/**
 * The words as verses and refrains. `repeat` sings the refrain after every verse (the book prints it
 * once, after the first). Verse numbers count verses only.
 */
export function versesOf(lyrics: string, repeat = false): Verse[] {
  const blocks = lyrics
    .replace(/\r\n?/g, '\n')
    .split(/\n\s*\n/)
    .map((v) => v.trim())
    .filter(Boolean);
  const out: Verse[] = [];
  let n = 0;
  const refrains = new Set<string>();
  for (const b of blocks) {
    const m = /^(refrain|chorus)\s*:?\s*\n?/i.exec(b);
    if (m) {
      const refrain = b.slice(m[0].length).trim();
      refrains.add(refrain);
      out.push({ kind: 'refrain', text: refrain, number: 0 });
    } else {
      n += 1;
      out.push({ kind: 'verse', text: b, number: n });
    }
  }
  // A hymn whose refrain changes from verse to verse (140) is left as the book prints it.
  if (!repeat || refrains.size !== 1) return out;
  const refrain = [...refrains][0];
  // Every verse followed by the refrain, once each.
  const verses = out.filter((v) => v.kind === 'verse');
  return verses.flatMap((v) => [v, { kind: 'refrain' as const, text: refrain, number: 0 }]);
}

/** The words as plain text for sharing and copying. */
export function plainWords(h: Hymn): string {
  return versesOf(h.lyrics)
    .map((v) => (v.kind === 'refrain' ? `Refrain:\n${v.text}` : `${v.number}. ${v.text}`))
    .join('\n\n');
}

/** Hymns grouped by section in the book's own order. */
export function groupBySection(hymns: Hymn[]): { section: string; hymns: Hymn[] }[] {
  const groups: { section: string; hymns: Hymn[] }[] = [];
  for (const h of hymns) {
    const section = h.section.trim() || 'Hymns';
    const last = groups[groups.length - 1];
    if (last && last.section === section) last.hymns.push(h);
    else groups.push({ section, hymns: [h] });
  }
  return groups;
}

export const SECTIONS = groupBySection(HYMNS);

/**
 * The book's parts, each a run of numbers holding several sections. `tone` is the card's gradient.
 */
export const PARTS: { name: string; from: number; to: number; icon: 'sun' | 'star' | 'heart' | 'bible' | 'sparkle' | 'book' | 'church' | 'lesson' | 'clock' | 'people' | 'home' | 'music'; tone: readonly [string, string] }[] = [
  { name: 'Worship', from: 1, to: 69, icon: 'sun', tone: ['#f59e0b', '#b45309'] },
  { name: 'Trinity', from: 70, to: 73, icon: 'sparkle', tone: ['#8b5cf6', '#5b21b6'] },
  { name: 'God the Father', from: 74, to: 114, icon: 'star', tone: ['#0ea5e9', '#0369a1'] },
  { name: 'Jesus Christ', from: 115, to: 256, icon: 'heart', tone: ['#ef4444', '#991b1b'] },
  { name: 'Holy Spirit', from: 257, to: 270, icon: 'sparkle', tone: ['#14b8a6', '#0f766e'] },
  { name: 'Holy Scriptures', from: 271, to: 278, icon: 'bible', tone: ['#a16207', '#713f12'] },
  { name: 'Gospel', from: 279, to: 343, icon: 'book', tone: ['#22c55e', '#15803d'] },
  { name: 'Christian Church', from: 344, to: 379, icon: 'church', tone: ['#6366f1', '#3730a3'] },
  { name: 'Doctrines', from: 380, to: 437, icon: 'lesson', tone: ['#0891b2', '#164e63'] },
  { name: 'Early Advent', from: 438, to: 454, icon: 'clock', tone: ['#d946ef', '#86198f'] },
  { name: 'Christian Life', from: 455, to: 649, icon: 'people', tone: ['#10b981', '#065f46'] },
  { name: 'Christian Home', from: 650, to: 659, icon: 'home', tone: ['#f97316', '#9a3412'] },
  { name: 'Sentences and Responses', from: 660, to: 695, icon: 'music', tone: ['#64748b', '#334155'] },
];

/** The sections inside a part, in order. */
export function sectionsOfPart(from: number, to: number) {
  return SECTIONS.filter((g) => g.hymns[0].number >= from && g.hymns[0].number <= to);
}

/** Today's hymn: the same for everyone on the same day, a different one each day, always one with words. */
export function hymnOfTheDay(date = new Date()): Hymn {
  const withWords = HYMNS.filter((h) => h.lyrics && h.number < 660);
  const day = Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86400000);
  // A stride coprime with the list's length walks through every hymn before repeating.
  return withWords[(day * 37) % withWords.length];
}
