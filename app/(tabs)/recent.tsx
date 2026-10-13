import React, { useMemo } from 'react';
import { Alert, FlatList, Pressable } from 'react-native';
import { useRouter } from 'expo-router';
import { HymnLine, useOpenHymn } from '../../src/components/HymnLine';
import { useTabBarSpace } from '../../src/components/TabBar';
import { Text } from '../../src/components/Text';
import { Button, Empty, Screen, TabHeader } from '../../src/components/ui';
import { hymnByNumber, type Hymn } from '../../src/lib/hymnal';
import { setPrefs, usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

/** Hymns opened lately, newest first. */
export default function Recent() {
  const prefs = usePrefs();
  const router = useRouter();
  const open = useOpenHymn();
  const bottom = useTabBarSpace();
  const hymns = useMemo(() => prefs.recent.map(hymnByNumber).filter((h): h is Hymn => !!h), [prefs.recent]);

  const clear = () =>
    Alert.alert('Clear recent hymns?', undefined, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Clear', style: 'destructive', onPress: () => setPrefs({ recent: [] }) },
    ]);

  return (
    <Screen>
      <TabHeader
        title="Recent"
        right={
          hymns.length ? (
            <Pressable onPress={clear} hitSlop={8} accessibilityRole="button">
              <Text style={{ color: C.accent2, fontSize: 16.5, fontWeight: '700' }}>Clear</Text>
            </Pressable>
          ) : null
        }
      />
      <FlatList
        data={hymns}
        keyExtractor={(h) => String(h.number)}
        contentContainerStyle={{ paddingTop: 4, paddingBottom: bottom }}
        renderItem={({ item }) => <HymnLine hymn={item} onOpen={open} sub={item.author || item.section} starred={prefs.favourites.includes(item.number)} />}
        ListEmptyComponent={
          prefs.history ? (
            <Empty icon="history" title="Nothing yet" body="Hymns you open will show here." action={<Button label="Browse the hymnal" small style={{ marginTop: 6 }} onPress={() => router.navigate('/')} />} />
          ) : (
            <Empty icon="history" title="History is off" action={<Button label="Turn on" small style={{ marginTop: 6 }} onPress={() => setPrefs({ history: true })} />} />
          )
        }
      />
    </Screen>
  );
}
