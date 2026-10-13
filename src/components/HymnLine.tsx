import React, { useCallback, useRef } from 'react';
import { Pressable, View } from 'react-native';
import { useRouter } from 'expo-router';
import type { Hymn } from '../lib/hymnal';
import { C } from '../lib/theme';
import { Icon } from './Icon';
import { serif, Text } from './Text';

/** One hymn in a list, as on the SDA app's Hymnal: its number, then its title. `sub` adds a second line. */
export const HymnLine = React.memo(function HymnLine({ hymn, onOpen, sub, starred }: { hymn: Hymn; onOpen: (n: number) => void; sub?: string; starred?: boolean }) {
  return (
    <Pressable onPress={() => onOpen(hymn.number)} accessibilityRole="button" accessibilityLabel={`Hymn ${hymn.number}, ${hymn.title}`} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 14, paddingHorizontal: 16, minHeight: sub ? 60 : 50, backgroundColor: pressed ? C.press : 'transparent' })}>
      <Text style={[serif(500), { width: 42, textAlign: 'right', color: C.fg2, fontSize: 19, fontVariant: ['tabular-nums', 'lining-nums'] }]}>{hymn.number}</Text>
      <View style={{ flex: 1 }}>
        <Text numberOfLines={1} style={{ color: C.fg, fontSize: 16.5, fontWeight: '500' }}>{hymn.title}</Text>
        {sub ? <Text numberOfLines={1} style={{ color: C.fg2, fontSize: 13.5, marginTop: 1 }}>{sub}</Text> : null}
      </View>
      {starred ? <Icon name="heart" size={15} color={C.like} fill /> : null}
      <Icon name="right" size={18} color={C.fg3} weight={2} />
    </Pressable>
  );
});

/** Opens a hymn, once per double tap. */
export function useOpenHymn() {
  const router = useRouter();
  const openedAt = useRef(0);
  return useCallback(
    (n: number) => {
      const now = Date.now();
      if (now - openedAt.current < 700) return;
      openedAt.current = now;
      router.push({ pathname: '/hymn/[number]', params: { number: String(n) } });
    },
    [router],
  );
}
