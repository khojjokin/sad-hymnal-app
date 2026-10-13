import React, { useMemo } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useOpenHymn } from '../../src/components/HymnLine';
import { Icon } from '../../src/components/Icon';
import { useTabBarSpace } from '../../src/components/TabBar';
import { serif, Text } from '../../src/components/Text';
import { pressFx, Screen, SectionLabel, TabHeader } from '../../src/components/ui';
import { hymnOfTheDay, PARTS, sectionsOfPart, versesOf } from '../../src/lib/hymnal';
import { C } from '../../src/lib/theme';

/** The hymnal by its parts (Worship, Jesus Christ, Christian Life…), with today's hymn at the top. */
export default function Topics() {
  const router = useRouter();
  const open = useOpenHymn();
  const bottom = useTabBarSpace();
  const today = useMemo(() => hymnOfTheDay(), []);
  const firstLines = useMemo(() => (versesOf(today.lyrics)[0]?.text ?? '').split('\n').slice(0, 2).join('\n'), [today]);

  return (
    <Screen>
      <TabHeader title="Topics" />
      <ScrollView contentContainerStyle={{ paddingBottom: bottom }}>
        {/* Today's hymn: its number large, as on the hymn page, and the opening lines. */}
        <Pressable onPress={() => open(today.number)} accessibilityRole="button" accessibilityLabel={`Today's hymn, ${today.number}, ${today.title}`} style={({ pressed }) => [{ marginHorizontal: 16, marginTop: 4, padding: 18, borderRadius: 22, backgroundColor: C.surface, flexDirection: 'row', gap: 16 }, pressFx(pressed, 0.98)]}>
          <Text style={[serif(600), { color: C.accent2, fontSize: 52, lineHeight: 56, letterSpacing: -1.5, fontVariant: ['lining-nums'] }]}>{today.number}</Text>
          <View style={{ flex: 1, paddingTop: 4 }}>
            <Text style={{ color: C.fg2, fontSize: 13.5, fontWeight: '600' }}>Today's hymn</Text>
            <Text numberOfLines={2} style={[serif(600), { color: C.fg, fontSize: 23, lineHeight: 27, marginTop: 2 }]}>{today.title}</Text>
            <Text numberOfLines={2} style={[serif('italic'), { color: C.fg2, fontSize: 16, lineHeight: 22, marginTop: 8 }]}>{firstLines}</Text>
          </View>
        </Pressable>

        <SectionLabel>Parts of the hymnal</SectionLabel>
        {PARTS.map((p, i) => {
          const topics = sectionsOfPart(p.from, p.to).length;
          return (
            <Pressable key={p.name} onPress={() => router.push({ pathname: '/part/[index]', params: { index: String(i) } })} accessibilityRole="button" accessibilityLabel={`${p.name}, hymns ${p.from} to ${p.to}`} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 14, paddingHorizontal: 16, minHeight: 66, backgroundColor: pressed ? C.press : 'transparent' })}>
              {/* The part's own colour, as a small mark, so the list scans without turning into a wall of tiles. */}
              <View style={{ width: 40, height: 40, borderRadius: 12, backgroundColor: p.tone[0], alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={p.icon} size={20} color="#ffffff" weight={2.1} />
              </View>
              <View style={{ flex: 1, paddingVertical: 10, borderBottomWidth: i === PARTS.length - 1 ? 0 : StyleSheet.hairlineWidth, borderBottomColor: C.line }}>
                <Text numberOfLines={1} style={[serif(600), { color: C.fg, fontSize: 20, lineHeight: 25 }]}>{p.name}</Text>
                <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 1 }}>
                  Hymns {p.from}–{p.to}
                  {topics > 1 ? `, ${topics} topics` : ''}
                </Text>
              </View>
              <Icon name="right" size={18} color={C.fg3} weight={2} />
            </Pressable>
          );
        })}
      </ScrollView>
    </Screen>
  );
}
