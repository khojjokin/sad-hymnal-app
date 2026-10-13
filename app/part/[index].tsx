import React, { useCallback, useMemo } from 'react';
import { FlatList, ScrollView, View } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HymnLine, useOpenHymn } from '../../src/components/HymnLine';
import { Text } from '../../src/components/Text';
import { Screen, ScreenHeader, SectionLabel } from '../../src/components/ui';
import { PARTS, sectionsOfPart, type Hymn } from '../../src/lib/hymnal';
import { usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

type Item = { kind: 'header'; key: string; title: string } | { kind: 'hymn'; key: string; hymn: Hymn };

/** One part of the hymnal: its topics, each with its hymns. A chip row jumps to a topic. */
export default function Part() {
  const { index } = useLocalSearchParams<{ index: string }>();
  const part = PARTS[Math.min(PARTS.length - 1, Math.max(0, parseInt(String(index ?? '0'), 10) || 0))];
  const insets = useSafeAreaInsets();
  const open = useOpenHymn();
  const prefs = usePrefs();
  const sections = useMemo(() => sectionsOfPart(part.from, part.to), [part]);
  const list = React.useRef<FlatList<Item>>(null);

  const items = useMemo<Item[]>(() => {
    const out: Item[] = [];
    sections.forEach((g) => {
      if (sections.length > 1) out.push({ kind: 'header', key: `h-${g.section}`, title: g.section });
      g.hymns.forEach((h) => out.push({ kind: 'hymn', key: `s${h.number}`, hymn: h }));
    });
    return out;
  }, [sections]);

  const jump = (section: string) => {
    const i = items.findIndex((x) => x.kind === 'header' && x.title === section);
    if (i >= 0) list.current?.scrollToIndex({ index: i, animated: true });
  };

  const renderItem = useCallback(({ item }: { item: Item }) => (item.kind === 'header' ? <SectionLabel>{item.title}</SectionLabel> : <HymnLine hymn={item.hymn} onOpen={open} starred={prefs.favourites.includes(item.hymn.number)} />), [open, prefs.favourites]);

  return (
    <Screen>
      <ScreenHeader title={part.name} />
      <FlatList
        ref={list}
        data={items}
        keyExtractor={(x) => x.key}
        renderItem={renderItem}
        initialNumToRender={40}
        // A topic further down than the list has drawn: jump near it first, then settle on it.
        onScrollToIndexFailed={(e) => {
          list.current?.scrollToOffset({ offset: e.averageItemLength * e.index, animated: false });
          setTimeout(() => list.current?.scrollToIndex({ index: e.index, animated: true }), 120);
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + 30 }}
        ListHeaderComponent={
          <View>
            <Text style={{ color: C.fg2, fontSize: 14.5, paddingHorizontal: 16, paddingBottom: sections.length > 1 ? 12 : 4 }}>
              Hymns {part.from}–{part.to}
            </Text>
            {sections.length > 1 ? (
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8, paddingHorizontal: 16 }}>
                {sections.map((g) => (
                  <Text key={g.section} onPress={() => jump(g.section)} accessibilityRole="button" style={{ color: C.fg, fontSize: 14, fontWeight: '600', paddingHorizontal: 14, paddingVertical: 8, borderRadius: 10, overflow: 'hidden', backgroundColor: C.surface }}>
                    {g.section}
                  </Text>
                ))}
              </ScrollView>
            ) : null}
          </View>
        }
      />
    </Screen>
  );
}
