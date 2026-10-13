import React from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colourById, colourStops, HYMN_COLOURS, swatchStops, type HymnColour } from '../lib/colours';
import { tap } from '../lib/haptics';
import { setPrefs, usePrefs } from '../lib/prefs';
import { C, themeName } from '../lib/theme';
import { Icon } from './Icon';
import { Text } from './Text';
import { Button, Sheet } from './ui';

/*
 * Choosing the colour behind the hymns: a live picture of a hymn page at the top (the page behind the
 * sheet changes too), then Default and every colour. A choice is kept at once; Done closes.
 */

const START = { x: 0, y: 0 };
const END = { x: 1, y: 1 };
const SWATCH = 40;

/** A little hymn page in a colour: a number, a title and two verses of lines. */
export function HymnPreview({ stops, height = 140 }: { stops: string[] | null; height?: number }) {
  const body = (
    <View style={{ flex: 1, padding: 16, gap: 8 }}>
      <View style={{ width: 52, height: 8, borderRadius: 4, backgroundColor: C.fg3 }} />
      <View style={{ width: '58%', height: 13, borderRadius: 6, backgroundColor: C.fg }} />
      <View style={{ gap: 6, marginTop: 6 }}>
        {[0.8, 0.66, 0.74].map((w, i) => (
          <View key={i} style={{ flexDirection: 'row', gap: 8, alignItems: 'center' }}>
            {i === 0 ? <View style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: C.accent2 }} /> : <View style={{ width: 8 }} />}
            <View style={{ width: `${w * 100}%`, height: 7, borderRadius: 4, backgroundColor: C.fg2 }} />
          </View>
        ))}
      </View>
    </View>
  );
  const frame: ViewStyle = { height, borderRadius: 20, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth, borderColor: C.hairline };
  if (!stops) return <View style={[frame, { backgroundColor: C.bg }]}>{body}</View>;
  return (
    <LinearGradient colors={stops as unknown as readonly [string, string, ...string[]]} start={START} end={END} style={frame}>
      {body}
    </LinearGradient>
  );
}

/** One round swatch, ringed in green with a tick when chosen. */
export function Swatch({ colour, on, onPress }: { colour: HymnColour | null; on: boolean; onPress: () => void }) {
  const stops = colour ? swatchStops(colour, themeName()) : null;
  return (
    <Pressable onPress={onPress} accessibilityRole="radio" accessibilityState={{ checked: on }} accessibilityLabel={colour?.name ?? 'Default'} hitSlop={4} style={({ pressed }) => ({ width: SWATCH + 10, height: SWATCH + 10, borderRadius: (SWATCH + 10) / 2, alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: on ? C.accent : 'transparent', transform: [{ scale: pressed ? 0.92 : 1 }] })}>
      {stops ? (
        <LinearGradient colors={stops as unknown as readonly [string, string, ...string[]]} start={START} end={END} style={{ width: SWATCH, height: SWATCH, borderRadius: SWATCH / 2, borderWidth: StyleSheet.hairlineWidth, borderColor: C.hairline }} />
      ) : (
        <View style={{ width: SWATCH, height: SWATCH, borderRadius: SWATCH / 2, backgroundColor: C.bg, borderWidth: 1, borderColor: C.line, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
          <View style={{ width: SWATCH * 1.2, height: 1.5, backgroundColor: C.fg3, transform: [{ rotate: '-45deg' }] }} />
        </View>
      )}
      {on ? (
        <View style={{ position: 'absolute', right: -1, bottom: -1, width: 19, height: 19, borderRadius: 10, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: C.sheet }}>
          <Icon name="check" size={10} color="#ffffff" weight={3} />
        </View>
      ) : null}
    </Pressable>
  );
}

/** Default and every colour, in rows; `onChoose` gets the colour's id ('' for Default). */
export function Swatches({ chosen, onChoose }: { chosen: string; onChoose: (id: string) => void }) {
  return (
    <View accessibilityRole="radiogroup" style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', columnGap: 4, rowGap: 6 }}>
      <Swatch colour={null} on={!chosen} onPress={() => onChoose('')} />
      {HYMN_COLOURS.map((c) => (
        <Swatch key={c.id} colour={c} on={chosen === c.id} onPress={() => onChoose(c.id)} />
      ))}
    </View>
  );
}

export function chooseColour(id: string) {
  tap('select');
  setPrefs({ hymnColour: id });
}

export function ColourSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const prefs = usePrefs();
  const colour = colourById(prefs.hymnColour);
  const stops = colour ? colourStops(colour, themeName(), true) : null;
  return (
    <Sheet visible={visible} onClose={onClose} title="Hymn background">
      <View style={{ paddingHorizontal: 20, paddingBottom: 6, gap: 16 }}>
        <View>
          <HymnPreview stops={stops} />
          <Text style={{ color: C.fg2, fontSize: 13.5, textAlign: 'center', marginTop: 8 }} accessibilityLiveRegion="polite">
            {colour?.name ?? 'Default'}
          </Text>
        </View>
        <Swatches chosen={prefs.hymnColour} onChoose={chooseColour} />
        <Button label="Done" kind="ghost" onPress={onClose} />
      </View>
    </Sheet>
  );
}
