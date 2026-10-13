import React, { useCallback, useMemo, useState } from 'react';
import { Animated, Pressable, View } from 'react-native';
import { Backdrop } from '../../src/components/Backdrop';
import { ColourSheet } from '../../src/components/ColourSheet';
import { HymnLine, useOpenHymn } from '../../src/components/HymnLine';
import { Icon } from '../../src/components/Icon';
import { NumberSheet } from '../../src/components/NumberSheet';
import { PHOTOS } from '../../src/components/Photo';
import { HERO_SEARCH, HeroButton, HeroSearch, PhotoHero, useHeroLayout, useHeroScroll } from '../../src/components/PhotoHero';
import { useTabBarSpace } from '../../src/components/TabBar';
import { Text } from '../../src/components/Text';
import { Empty, Screen, SectionLabel } from '../../src/components/ui';
import { HYMN_COUNT, hymnByNumber, HYMNS, SEARCH_INDEX, searchKey, SECTIONS, type Hymn } from '../../src/lib/hymnal';
import { usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

/** The list is flat so every row has its own key: a hymn can sit under Favourites and under its section. */
type Item = { kind: 'header'; key: string; title: string } | { kind: 'hymn'; key: string; hymn: Hymn };

export default function Hymnal() {
  const { scroll, onScroll } = useHeroScroll();
  const { paddingTop } = useHeroLayout(HERO_SEARCH);
  const bottom = useTabBarSpace();
  const prefs = usePrefs();
  const open = useOpenHymn();
  const [q, setQ] = useState('');
  const [palette, setPalette] = useState(false);
  const [keypad, setKeypad] = useState(false);

  const needle = q.trim();
  const asNumber = /^\d+$/.test(needle) ? parseInt(needle, 10) : 0;
  const exact = asNumber >= 1 && asNumber <= HYMN_COUNT ? hymnByNumber(asNumber) : undefined;

  const items = useMemo<Item[]>(() => {
    const row = (h: Hymn, prefix: string): Item => ({ kind: 'hymn', key: `${prefix}${h.number}`, hymn: h });
    if (needle) {
      // Digits match the start of the number (so "10" shows 10 and 100–109); words must all appear.
      if (asNumber) return HYMNS.filter((h) => String(h.number).startsWith(needle)).map((h) => row(h, 's'));
      const words = searchKey(needle).split(' ').filter(Boolean);
      if (!words.length) return [];
      // Titles first, then hymns found by their author or first line.
      const inTitle = SEARCH_INDEX.filter((x) => words.every((w) => x.title.includes(w)));
      const seen = new Set(inTitle.map((x) => x.hymn.number));
      const elsewhere = SEARCH_INDEX.filter((x) => !seen.has(x.hymn.number) && words.every((w) => x.all.includes(w)));
      const out = inTitle.map((x) => row(x.hymn, 's'));
      if (elsewhere.length) {
        out.push({ kind: 'header', key: 'h-more', title: 'By author or first line' });
        elsewhere.forEach((x) => out.push(row(x.hymn, 'e')));
      }
      return out;
    }
    const out: Item[] = [];
    const starred = [...prefs.favourites].sort((a, b) => a - b).map(hymnByNumber).filter((h): h is Hymn => !!h);
    if (starred.length) {
      out.push({ kind: 'header', key: 'h-favourites', title: 'Favourites' });
      starred.forEach((h) => out.push(row(h, 'f')));
    }
    SECTIONS.forEach((g, i) => {
      out.push({ kind: 'header', key: `h-${i}-${g.section}`, title: g.section });
      g.hymns.forEach((h) => out.push(row(h, 's')));
    });
    return out;
  }, [needle, asNumber, prefs.favourites]);

  const renderItem = useCallback(({ item }: { item: Item }) => (item.kind === 'header' ? <SectionLabel>{item.title}</SectionLabel> : <HymnLine hymn={item.hymn} onOpen={open} />), [open]);

  return (
    <Screen edges={false}>
      <Backdrop where="list" />
      <Animated.FlatList
        data={items}
        keyExtractor={(it) => it.key}
        onScroll={onScroll}
        scrollEventThrottle={16}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        initialNumToRender={24}
        maxToRenderPerBatch={24}
        windowSize={11}
        contentContainerStyle={{ paddingTop, paddingBottom: bottom }}
        ListHeaderComponent={
          exact ? (
            <Pressable onPress={() => open(exact.number)} accessibilityRole="button" accessibilityLabel={`Open hymn ${exact.number}, ${exact.title}`} style={({ pressed }) => ({ marginTop: 4, marginBottom: 6, paddingHorizontal: 16, paddingVertical: 12, backgroundColor: pressed ? C.press : 'transparent', flexDirection: 'row', alignItems: 'center', gap: 12 })}>
              <Icon name="hymnal" size={24} color={C.accent2} />
              <View style={{ flex: 1 }}>
                <Text style={{ color: C.accent2, fontSize: 13, fontWeight: '700' }}>Open hymn {exact.number}</Text>
                <Text numberOfLines={1} style={{ color: C.fg, fontSize: 17, fontWeight: '700' }}>{exact.title}</Text>
              </View>
              <Icon name="right" size={18} color={C.fg2} weight={2} />
            </Pressable>
          ) : null
        }
        ListEmptyComponent={<Empty icon="search" title="No hymn matches" />}
        ListFooterComponent={!needle ? <Text style={{ color: C.fg3, fontSize: 12.5, textAlign: 'center', paddingTop: 22, paddingHorizontal: 24, lineHeight: 17 }}>Seventh-day Adventist Hymnal (1985) numbering</Text> : null}
        renderItem={renderItem}
      />
      <PhotoHero
        photo={PHOTOS.hymnal}
        title="Hymnal"
        line={`${HYMN_COUNT} hymns of the Seventh-day Adventist Hymnal`}
        scroll={scroll}
        left={<HeroButton name="hash" label="Go to hymn number" onPress={() => setKeypad(true)} />}
        right={<HeroButton name="palette" label="Hymn background" onPress={() => setPalette(true)} />}
        below={<HeroSearch value={q} onChangeText={setQ} placeholder="Number, title or first line" label="Search the hymnal" />}
        belowHeight={HERO_SEARCH}
      />
      <ColourSheet visible={palette} onClose={() => setPalette(false)} />
      <NumberSheet visible={keypad} onClose={() => setKeypad(false)} onOpen={open} />
    </Screen>
  );
}
