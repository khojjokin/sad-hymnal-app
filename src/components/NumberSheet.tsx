import React, { useState } from 'react';
import { Pressable, View } from 'react-native';
import { HYMN_COUNT, hymnByNumber } from '../lib/hymnal';
import { tap } from '../lib/haptics';
import { C } from '../lib/theme';
import { Icon } from './Icon';
import { serif, Text } from './Text';
import { Button, Sheet } from './ui';
import { useT } from '../lib/i18n';

/*
 * Go to a hymn by its number, as the board at the front of the church shows it: a keypad, the number
 * as it's typed, and the hymn's title under it so you know it's the right one before opening it.
 */
export function NumberSheet({ visible, onClose, onOpen }: { visible: boolean; onClose: () => void; onOpen: (n: number) => void }) {
  const t = useT();
  const [digits, setDigits] = useState('');
  const n = parseInt(digits || '0', 10);
  const hymn = n >= 1 && n <= HYMN_COUNT ? hymnByNumber(n) : undefined;

  const press = (d: string) => {
    tap('select');
    if (d === 'del') return setDigits((s) => s.slice(0, -1));
    setDigits((s) => {
      const next = (s + d).replace(/^0+/, '');
      return parseInt(next || '0', 10) > HYMN_COUNT ? s : next.slice(0, 3);
    });
  };
  const open = () => {
    if (!hymn) return;
    onClose();
    setDigits('');
    onOpen(hymn.number);
  };
  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];

  return (
    <Sheet visible={visible} onClose={onClose} title={t('number.title')}>
      <View style={{ paddingHorizontal: 24, gap: 14 }}>
        <View style={{ alignItems: 'center', minHeight: 86 }}>
          <Text style={[serif(600), { color: digits ? C.accent2 : C.fg3, fontSize: 64, lineHeight: 70, fontVariant: ['tabular-nums', 'lining-nums'], letterSpacing: -1 }]}>{digits || '—'}</Text>
          <Text numberOfLines={1} style={[serif(hymn ? 'italic' : 400), { color: hymn ? C.fg : C.fg3, fontSize: 18, marginTop: 2 }]}>{hymn ? hymn.title : t('number.range', { n: HYMN_COUNT })}</Text>
        </View>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', rowGap: 10 }}>
          {keys.map((k, i) =>
            k ? (
              <Pressable key={i} onPress={() => press(k)} accessibilityRole="button" accessibilityLabel={k === 'del' ? t('number.delete') : k} style={({ pressed }) => ({ width: '31.5%', height: 58, borderRadius: 16, backgroundColor: pressed ? C.surface2 : C.surface, alignItems: 'center', justifyContent: 'center' })}>
                {k === 'del' ? <Icon name="back" size={24} color={C.fg} weight={2.2} /> : <Text style={[serif(500), { color: C.fg, fontSize: 28 }]}>{k}</Text>}
              </Pressable>
            ) : (
              <View key={i} style={{ width: '31.5%', height: 58 }} />
            ),
          )}
        </View>
        <Button label={hymn ? t('number.openN', { n: hymn.number }) : t('number.open')} disabled={!hymn} onPress={open} />
      </View>
    </Sheet>
  );
}
