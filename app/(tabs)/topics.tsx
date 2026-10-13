import React, { useMemo } from 'react';
import { Pressable, ScrollView, StyleSheet, useWindowDimensions, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import { useOpenHymn } from '../../src/components/HymnLine';
import { Icon } from '../../src/components/Icon';
import { useTabBarSpace } from '../../src/components/TabBar';
import { Text } from '../../src/components/Text';
import { pressFx, Screen, SectionLabel, TabHeader } from '../../src/components/ui';
import { hymnOfTheDay, PARTS, sectionsOfPart, versesOf } from '../../src/lib/hymnal';

/** The hymnal by its parts (Worship, Jesus Christ, Christian Life…), with today's hymn at the top. */
export default function Topics() {
  const router = useRouter();
  const open = useOpenHymn();
  const bottom = useTabBarSpace();
  const { width } = useWindowDimensions();
  const today = useMemo(() => hymnOfTheDay(), []);
  const firstLines = useMemo(() => (versesOf(today.lyrics)[0]?.text ?? '').split('\n').slice(0, 2).join('\n'), [today]);
  const tile = (Math.min(width, 640) - 16 * 2 - 12) / 2;

  return (
    <Screen>
      <TabHeader title="Topics" />
      <ScrollView contentContainerStyle={{ paddingBottom: bottom }}>
        <Pressable onPress={() => open(today.number)} accessibilityRole="button" accessibilityLabel={`Hymn of the day, ${today.number}, ${today.title}`} style={({ pressed }) => [{ marginHorizontal: 16, marginTop: 4, borderRadius: 22, overflow: 'hidden' }, pressFx(pressed, 0.98)]}>
          <LinearGradient colors={['#1fbf5a', '#0d7a3a', '#0b3d22']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={{ padding: 20, gap: 8 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <Icon name="sun" size={18} color="#ffffff" weight={2.2} />
              <Text style={{ color: 'rgba(255,255,255,0.9)', fontSize: 12.5, fontWeight: '700', letterSpacing: 1.2, textTransform: 'uppercase' }}>Hymn of the day · {today.number}</Text>
            </View>
            <Text numberOfLines={2} style={{ color: '#ffffff', fontSize: 25, lineHeight: 30, fontWeight: '800', letterSpacing: -0.3 }}>{today.title}</Text>
            <Text numberOfLines={2} style={{ color: 'rgba(255,255,255,0.86)', fontSize: 15, lineHeight: 21 }}>{firstLines}</Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 6 }}>
              <Text style={{ color: '#ffffff', fontSize: 14.5, fontWeight: '700' }}>Sing it</Text>
              <Icon name="arrow" size={16} color="#ffffff" weight={2.2} />
            </View>
          </LinearGradient>
        </Pressable>

        <SectionLabel>Parts of the hymnal</SectionLabel>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 12, paddingHorizontal: 16 }}>
          {PARTS.map((p, i) => {
            const count = p.to - p.from + 1;
            const sections = sectionsOfPart(p.from, p.to).length;
            return (
              <Pressable key={p.name} onPress={() => router.push({ pathname: '/part/[index]', params: { index: String(i) } })} accessibilityRole="button" accessibilityLabel={`${p.name}, ${count} hymns`} style={({ pressed }) => [{ width: tile, height: 118, borderRadius: 20, overflow: 'hidden' }, pressFx(pressed, 0.96)]}>
                <LinearGradient colors={p.tone} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
                <View style={{ flex: 1, padding: 14, justifyContent: 'space-between' }}>
                  <View style={{ width: 36, height: 36, borderRadius: 18, backgroundColor: 'rgba(255,255,255,0.2)', alignItems: 'center', justifyContent: 'center' }}>
                    <Icon name={p.icon} size={20} color="#ffffff" weight={2.1} />
                  </View>
                  <View>
                    <Text numberOfLines={2} style={{ color: '#ffffff', fontSize: 16.5, fontWeight: '700', lineHeight: 20 }}>{p.name}</Text>
                    <Text style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12.5, marginTop: 2 }}>
                      {p.from}–{p.to} · {sections > 1 ? `${sections} topics` : `${count} hymns`}
                    </Text>
                  </View>
                </View>
              </Pressable>
            );
          })}
        </View>
      </ScrollView>
    </Screen>
  );
}
