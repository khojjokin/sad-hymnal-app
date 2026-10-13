import React from 'react';
import { Pressable, View } from 'react-native';
import { tap } from '../lib/haptics';
import { C } from '../lib/theme';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';
import { Radio, Toggle, useOneTap } from './ui';

/*
 * Instagram's settings layout: grey section names in small type, rows with a line icon on the left, the
 * name, the current value in grey on the right and a chevron, and a thick grey band between sections.
 */

export function SettingsLabel({ children }: { children: string }) {
  return (
    <Text accessibilityRole="header" style={{ color: C.fg2, fontSize: 14, fontWeight: '600', paddingHorizontal: 16, paddingTop: 18, paddingBottom: 6 }}>
      {children}
    </Text>
  );
}

/** The thick band between sections. */
export function Band() {
  return <View style={{ height: 8, backgroundColor: C.field, marginTop: 10 }} />;
}

export function SettingsRow({ icon, title, value, onPress, toggle, onToggle, danger, sub }: { icon?: IconName; title: string; value?: string; onPress?: () => void; toggle?: boolean; onToggle?: (v: boolean) => void; danger?: boolean; sub?: string }) {
  const press = useOneTap(onPress ? () => { tap('light'); onPress(); } : undefined);
  const color = danger ? C.like : C.fg;
  const body = (
    <>
      {icon ? <Icon name={icon} size={24} color={color} weight={1.8} /> : null}
      <View style={{ flex: 1, paddingVertical: sub ? 8 : 0 }}>
        <Text style={{ color, fontSize: 16.5, fontWeight: danger ? '600' : '400' }}>{title}</Text>
        {sub ? <Text style={{ color: C.fg2, fontSize: 13.5, lineHeight: 18, marginTop: 2 }}>{sub}</Text> : null}
      </View>
      {value ? <Text numberOfLines={1} style={{ color: C.fg2, fontSize: 15.5, maxWidth: '45%' }}>{value}</Text> : null}
      {onToggle && toggle !== undefined ? <Toggle value={toggle} onChange={onToggle} label={title} /> : null}
      {onPress && !onToggle && !danger ? <Icon name="right" size={17} color={C.fg2} weight={2} /> : null}
    </>
  );
  const style = { flexDirection: 'row' as const, alignItems: 'center' as const, gap: 14, paddingHorizontal: 16, minHeight: 54 };
  if (onToggle && toggle !== undefined) {
    return (
      <Pressable onPress={() => { tap('select'); onToggle(!toggle); }} accessibilityRole="switch" accessibilityState={{ checked: toggle }} accessibilityLabel={title} style={({ pressed }) => [style, { backgroundColor: pressed ? C.press : 'transparent' }]}>
        {body}
      </Pressable>
    );
  }
  if (!press) return <View style={style}>{body}</View>;
  return (
    <Pressable onPress={press} accessibilityRole="button" accessibilityLabel={[title, value].filter(Boolean).join(', ')} style={({ pressed }) => [style, { backgroundColor: pressed ? C.press : 'transparent' }]}>
      {body}
    </Pressable>
  );
}

/** One answer in a list of choices, with a radio on the right (Instagram's). */
export function ChoiceRow({ title, sub, on, onPress, left }: { title: string; sub?: string; on: boolean; onPress: () => void; left?: React.ReactNode }) {
  return (
    <Pressable onPress={() => { tap('select'); onPress(); }} accessibilityRole="radio" accessibilityState={{ checked: on }} accessibilityLabel={title} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 14, paddingHorizontal: 16, minHeight: 56, backgroundColor: pressed ? C.press : 'transparent' })}>
      {left}
      <View style={{ flex: 1, paddingVertical: sub ? 8 : 0 }}>
        <Text style={{ color: C.fg, fontSize: 16.5 }}>{title}</Text>
        {sub ? <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 2 }}>{sub}</Text> : null}
      </View>
      <Radio on={on} />
    </Pressable>
  );
}

/** A short grey line under a section. */
export function Caption({ children }: { children: string }) {
  return <Text style={{ color: C.fg2, fontSize: 13.5, lineHeight: 19, paddingHorizontal: 16, paddingTop: 8 }}>{children}</Text>;
}
