import React from 'react';
import { Pressable, ScrollView, View } from 'react-native';
import { useHymnLook } from '../../src/components/Backdrop';
import { LinearGradient } from 'expo-linear-gradient';
import { Band, ChoiceRow, SettingsLabel, SettingsRow } from '../../src/components/Settings';
import { SERIF, Text } from '../../src/components/Text';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { tap } from '../../src/lib/haptics';
import { setPrefs, TEXT_MAX, TEXT_MIN, usePrefs, type Spacing } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

const SPACING: Record<Spacing, number> = { compact: 1.38, normal: 1.55, relaxed: 1.75 };

/** How the words of a hymn read: size, face, spacing, verse numbers and the refrain. */
export default function Reading() {
  const prefs = usePrefs();
  const look = useHymnLook(true);
  const size = prefs.textSize;
  const face = prefs.font === 'serif' ? { fontFamily: SERIF } : null;
  const setSize = (n: number) => {
    tap('select');
    setPrefs({ textSize: Math.min(TEXT_MAX, Math.max(TEXT_MIN, n)) });
  };

  const sample = (
    <View style={{ padding: 18 }}>
      <Text style={[{ color: C.fg, fontSize: size, lineHeight: Math.round(size * SPACING[prefs.spacing]) }, face]}>
        {prefs.verseNumbers ? <Text style={{ color: C.accent2, fontSize: Math.round(size * 0.72), fontWeight: '700' }}>1  </Text> : null}
        Praise to the Lord, the Almighty, the King of creation!{'\n'}O my soul, praise Him, for He is thy health and salvation!
      </Text>
    </View>
  );

  return (
    <Screen>
      <ScreenHeader title="Text and reading" />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <View style={{ marginHorizontal: 16, marginTop: 6, borderRadius: 18, overflow: 'hidden', backgroundColor: C.surface }}>
          {look ? (
            <LinearGradient colors={look.stops as unknown as readonly [string, string, ...string[]]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
              {sample}
            </LinearGradient>
          ) : (
            sample
          )}
        </View>

        <SettingsLabel>Text size</SettingsLabel>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 16, paddingVertical: 6 }}>
          <Pressable onPress={() => setSize(size - 1)} disabled={size <= TEXT_MIN} accessibilityRole="button" accessibilityLabel="Smaller text" style={({ pressed }) => ({ width: 46, height: 40, borderRadius: 12, backgroundColor: pressed ? C.surface2 : C.surface, alignItems: 'center', justifyContent: 'center', opacity: size <= TEXT_MIN ? 0.4 : 1 })}>
            <Text style={{ color: C.fg, fontSize: 14, fontWeight: '700' }}>A</Text>
          </Pressable>
          {/* The steps between the smallest and largest, filled up to the size now. */}
          <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 3 }} accessibilityLabel={`Text size ${size}`} accessible>
            {Array.from({ length: TEXT_MAX - TEXT_MIN + 1 }, (_, i) => (
              <Pressable key={i} onPress={() => setSize(TEXT_MIN + i)} hitSlop={{ top: 12, bottom: 12 }} style={{ flex: 1, height: 6, borderRadius: 3, backgroundColor: TEXT_MIN + i <= size ? C.accent : C.surface2 }} />
            ))}
          </View>
          <Pressable onPress={() => setSize(size + 1)} disabled={size >= TEXT_MAX} accessibilityRole="button" accessibilityLabel="Larger text" style={({ pressed }) => ({ width: 46, height: 40, borderRadius: 12, backgroundColor: pressed ? C.surface2 : C.surface, alignItems: 'center', justifyContent: 'center', opacity: size >= TEXT_MAX ? 0.4 : 1 })}>
            <Text style={{ color: C.fg, fontSize: 20, fontWeight: '700' }}>A</Text>
          </Pressable>
        </View>
        <Text style={{ color: C.fg2, fontSize: 13.5, textAlign: 'center', paddingTop: 4 }}>{size} pt</Text>

        <Band />
        <SettingsLabel>Font</SettingsLabel>
        <ChoiceRow title="Outfit" sub="The app's own, clean and modern" on={prefs.font === 'app'} onPress={() => setPrefs({ font: 'app' })} />
        <ChoiceRow title="Serif" sub="Like a printed hymnal" on={prefs.font === 'serif'} onPress={() => setPrefs({ font: 'serif' })} />

        <Band />
        <SettingsLabel>Line spacing</SettingsLabel>
        {(['compact', 'normal', 'relaxed'] as const).map((s) => (
          <ChoiceRow key={s} title={s === 'compact' ? 'Compact' : s === 'normal' ? 'Normal' : 'Relaxed'} on={prefs.spacing === s} onPress={() => setPrefs({ spacing: s })} />
        ))}

        <Band />
        <SettingsLabel>Verses</SettingsLabel>
        <SettingsRow icon="hash" title="Verse numbers" toggle={prefs.verseNumbers} onToggle={(v) => setPrefs({ verseNumbers: v })} />
        <SettingsRow icon="repeat" title="Refrain after every verse" sub="Sing it through without scrolling back" toggle={prefs.repeatRefrain} onToggle={(v) => setPrefs({ repeatRefrain: v })} />
        <SettingsRow icon="screen" title="Keep screen on" toggle={prefs.keepAwake} onToggle={(v) => setPrefs({ keepAwake: v })} />
      </ScrollView>
    </Screen>
  );
}
