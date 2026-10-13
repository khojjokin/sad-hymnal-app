import React, { useMemo, useState } from 'react';
import { FlatList, Pressable, View } from 'react-native';
import { useRouter } from 'expo-router';
import { HymnLine, useOpenHymn } from '../../src/components/HymnLine';
import { Icon } from '../../src/components/Icon';
import { useTabBarSpace } from '../../src/components/TabBar';
import { Text } from '../../src/components/Text';
import { Button, Empty, Screen, TabHeader, toast } from '../../src/components/ui';
import { tap } from '../../src/lib/haptics';
import { hymnByNumber, type Hymn } from '../../src/lib/hymnal';
import { setPrefs, toggleFavourite, usePrefs } from '../../src/lib/prefs';
import { useT } from '../../src/lib/i18n';
import { C } from '../../src/lib/theme';

/** The hymns marked with the heart: by number, or newest first. Edit shows a remove button on each. */
export default function Favourites() {
  const t = useT();
  const prefs = usePrefs();
  const router = useRouter();
  const open = useOpenHymn();
  const bottom = useTabBarSpace();
  const [order, setOrder] = useState<'number' | 'added'>('number');
  const [editing, setEditing] = useState(false);

  const hymns = useMemo(() => {
    const list = order === 'number' ? [...prefs.favourites].sort((a, b) => a - b) : [...prefs.favourites].reverse();
    return list.map(hymnByNumber).filter((h): h is Hymn => !!h);
  }, [prefs.favourites, order]);

  const remove = (n: number) => {
    tap('light');
    const before = prefs.favourites;
    toggleFavourite(n);
    toast(t('hymn.unliked'));
    // Nothing left to edit: back to the plain list.
    if (before.length <= 1) setEditing(false);
  };

  const tabs = (['number', 'added'] as const).map((k) => {
    const on = order === k;
    return (
      <Pressable key={k} onPress={() => { tap('select'); setOrder(k); }} accessibilityRole="tab" accessibilityState={{ selected: on }} style={{ flex: 1, alignItems: 'center', paddingVertical: 11, borderBottomWidth: on ? 1.5 : 0.5, borderBottomColor: on ? C.fg : C.line }}>
        <Text style={{ color: on ? C.fg : C.fg2, fontSize: 15, fontWeight: on ? '700' : '500' }}>{k === 'number' ? t('fav.byNumber') : t('fav.byAdded')}</Text>
      </Pressable>
    );
  });

  return (
    <Screen>
      <TabHeader
        title={t('fav.title')}
        right={
          hymns.length ? (
            <Pressable onPress={() => { tap('light'); setEditing((e) => !e); }} hitSlop={8} accessibilityRole="button">
              <Text style={{ color: C.accent2, fontSize: 16.5, fontWeight: '700' }}>{editing ? t('fav.done') : t('fav.edit')}</Text>
            </Pressable>
          ) : null
        }
      />
      {hymns.length ? <View accessibilityRole="tablist" style={{ flexDirection: 'row' }}>{tabs}</View> : null}
      <FlatList
        data={hymns}
        keyExtractor={(h) => String(h.number)}
        contentContainerStyle={{ paddingTop: 6, paddingBottom: bottom }}
        renderItem={({ item }) => (
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <View style={{ flex: 1 }}>
              <HymnLine hymn={item} onOpen={open} sub={item.section} />
            </View>
            {editing ? (
              <Pressable onPress={() => remove(item.number)} hitSlop={6} accessibilityRole="button" accessibilityLabel={`${t('fav.remove')}: ${item.title}`} style={({ pressed }) => ({ marginRight: 16, height: 32, paddingHorizontal: 14, borderRadius: 10, backgroundColor: C.surface, justifyContent: 'center', opacity: pressed ? 0.6 : 1 })}>
                <Text style={{ color: C.fg, fontWeight: '600', fontSize: 14 }}>{t('fav.remove')}</Text>
              </Pressable>
            ) : null}
          </View>
        )}
        ListEmptyComponent={
          <Empty icon="heart" title={t('fav.emptyTitle')} body={t('fav.emptyBody')} action={<Button label={t('fav.browse')} small style={{ marginTop: 6 }} onPress={() => router.navigate('/')} />} />
        }
        ListFooterComponent={
          editing && hymns.length > 1 ? (
            <Pressable onPress={() => { setPrefs({ favourites: [] }); setEditing(false); toast(t('fav.cleared')); }} accessibilityRole="button" style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, paddingVertical: 20, opacity: pressed ? 0.6 : 1 })}>
              <Icon name="trash" size={18} color={C.like} />
              <Text style={{ color: C.like, fontWeight: '700', fontSize: 15.5 }}>{t('fav.removeAll')}</Text>
            </Pressable>
          ) : null
        }
      />
    </Screen>
  );
}
