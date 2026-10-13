import React, { useCallback, useMemo, useState } from 'react';
import { Animated, Pressable, ScrollView, View } from 'react-native';
import { HymnLine, useOpenHymn } from '../../src/components/HymnLine';
import { Icon } from '../../src/components/Icon';
import { NumberSheet } from '../../src/components/NumberSheet';
import { HERO_SEARCH, HeroButton, HeroSearch, PhotoHero, useHeroLayout, useHeroScroll } from '../../src/components/PhotoHero';
import { useTabBarSpace } from '../../src/components/TabBar';
import { serif, Text } from '../../src/components/Text';
import { Empty, pressFx, Screen, SectionLabel } from '../../src/components/ui';
import { HYMN_COUNT, hymnByNumber, HYMNS, SEARCH_INDEX, searchKey, SECTIONS, type Hymn } from '../../src/lib/hymnal';
import { useT } from '../../src/lib/i18n';
import { usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

/** The list is flat so every row has its own key: a hymn can sit under Favourites and under its section. */
type Item = { kind: 'header'; key: string; title: string } | { kind: 'hymn'; key: string; hymn: Hymn };

/** A hymn opened lately: its number large, its title under it. */
function RecentCard({ hymn, onOpen }: { hymn: Hymn; onOpen: (n: number) => void }) {
  return (
    <Pressable onPress={() => onOpen(hymn.number)} accessibilityRole="button" accessibilityLabel={`${hymn.number}, ${hymn.title}`} style={({ pressed }) => [{ width: 138, height: 112, padding: 14, borderRadius: 18, backgroundColor: C.surface, justifyContent: 'space-between' }, pressFx(pressed, 0.96)]}>
      <Text style={[serif(600), { color: C.accent2, fontSize: 30, lineHeight: 34, fontVariant: ['lining-nums'] }]}>{hymn.number}</Text>
      <Text numberOfLines={2} style={{ color: C.fg, fontSize: 14, fontWeight: '600', lineHeight: 18 }}>{hymn.title}</Text>
    </Pressable>
  );
}

export default function Hymnal() {
  const t = useT();
  const { scroll, onScroll } = useHeroScroll();
  const { paddingTop } = useHeroLayout(HERO_SEARCH);
  const bottom = useTabBarSpace();
  const prefs = usePrefs();
  const open = useOpenHymn();
  const [q, setQ] = useState('');
  const [keypad, setKeypad] = useState(false);

  const needle = q.trim();
  const asNumber = /^\d+$/.test(needle) ? parseInt(needle, 10) : 0;
  const exact = asNumber >= 1 && asNumber <= HYMN_COUNT ? hymnByNumber(asNumber) : undefined;
  const recent = useMemo(() => prefs.recent.slice(0, 10).map(hymnByNumber).filter((h): h is Hymn => !!h), [prefs.recent]);

  const items = useMemo<Item[]>(() => {
    const row = (h: Hymn, prefix: string): Item => ({ kind: 'hymn', key: `${prefix}${h.number}`, hymn: h });
    if (needle) {
      // Digits match the start of the number (so "10" shows 10 and 100–109); words must all appear.
      if (asNumber) return HYMNS.filter((h) => String(h.number).startsWith(needle)).map((h) => row(h, 's'));
      const words = searchKey(needle).split(' ').filter(Boolean);
      if (!words.length) return [];
      const inTitle = SEARCH_INDEX.filter((x) => words.every((w) => x.title.includes(w)));
      const seen = new Set(inTitle.map((x) => x.hymn.number));
      const elsewhere = SEARCH_INDEX.filter((x) => !seen.has(x.hymn.number) && words.every((w) => x.all.includes(w)));
      const out = inTitle.map((x) => row(x.hymn, 's'));
      if (elsewhere.length) {
        out.push({ kind: 'header', key: 'h-more', title: t('home.elsewhere') });
        elsewhere.forEach((x) => out.push(row(x.hymn, 'e')));
      }
      return out;
    }
    const out: Item[] = [];
    const starred = [...prefs.favourites].sort((a, b) => a - b).map(hymnByNumber).filter((h): h is Hymn => !!h);
    if (starred.length) {
      out.push({ kind: 'header', key: 'h-favourites', title: t('home.favourites') });
      starred.forEach((h) => out.push(row(h, 'f')));
    }
    SECTIONS.forEach((g, i) => {
      out.push({ kind: 'header', key: `h-${i}-${g.section}`, title: g.section });
      g.hymns.forEach((h) => out.push(row(h, 's')));
    });
    return out;
  }, [needle, asNumber, prefs.favourites, t]);

  const renderItem = useCallback(({ item }: { item: Item }) => (item.kind === 'header' ? <SectionLabel>{item.title}</SectionLabel> : <HymnLine hymn={item.hymn} onOpen={open} />), [open]);

  const header = exact ? (
    <Pressable onPress={() => open(exact.number)} accessibilityRole="button" accessibilityLabel={`${t('home.openHymn', { n: exact.number })}, ${exact.title}`} style={({ pressed }) => ({ marginTop: 6, marginHorizontal: 16, padding: 14, borderRadius: 16, backgroundColor: pressed ? C.surface2 : C.accentSoft, flexDirection: 'row', alignItems: 'center', gap: 14 })}>
      <Text style={[serif(600), { color: C.accent2, fontSize: 34, lineHeight: 38, fontVariant: ['lining-nums'] }]}>{exact.number}</Text>
      <View style={{ flex: 1 }}>
        <Text style={{ color: C.accent2, fontSize: 13, fontWeight: '700' }}>{t('home.openHymn', { n: exact.number })}</Text>
        <Text numberOfLines={1} style={{ color: C.fg, fontSize: 17, fontWeight: '600' }}>{exact.title}</Text>
      </View>
      <Icon name="right" size={18} color={C.fg2} weight={2} />
    </Pressable>
  ) : !needle && recent.length ? (
    <View>
      <SectionLabel>{t('home.recent')}</SectionLabel>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 10, paddingHorizontal: 16 }}>
        {recent.map((h) => (
          <RecentCard key={h.number} hymn={h} onOpen={open} />
        ))}
      </ScrollView>
    </View>
  ) : null;

  return (
    <Screen edges={false}>
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
        ListHeaderComponent={header}
        ListEmptyComponent={<Empty icon="search" title={t('home.noMatch')} />}
        ListFooterComponent={!needle ? <Text style={{ color: C.fg3, fontSize: 12.5, textAlign: 'center', paddingTop: 22, paddingHorizontal: 24, lineHeight: 17 }}>{t('home.footer')}</Text> : null}
        renderItem={renderItem}
      />
      <PhotoHero
        photo="tileHymnal"
        logo
        title={t('tab.hymnal')}
        line={t("home.subtitle")}
        scroll={scroll}
        right={<HeroButton name="hash" label={t('home.goTo')} onPress={() => setKeypad(true)} />}
        below={<HeroSearch value={q} onChangeText={setQ} placeholder={t('home.search')} label={t('home.searchLabel')} />}
        belowHeight={HERO_SEARCH}
      />
      <NumberSheet visible={keypad} onClose={() => setKeypad(false)} onOpen={open} />
    </Screen>
  );
}
