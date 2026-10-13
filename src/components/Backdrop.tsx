import React, { useEffect, useRef } from 'react';
import { Animated, StyleSheet, type ViewStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colourById, colourStops, type HymnColour } from '../lib/colours';
import { usePrefs } from '../lib/prefs';
import { themeName } from '../lib/theme';
import { reduceMotionNow } from './ui';

/**
 * The hymn background colour chosen in the palette (or Settings), with its stops in this theme, or null
 * on Default. `where` is 'list' for the hymnal's list, which follows only when Settings says so.
 */
export function useHymnLook(reading = false, where: 'hymn' | 'list' = 'hymn'): { colour: HymnColour; stops: string[] } | null {
  const prefs = usePrefs();
  const colour = colourById(prefs.hymnColour);
  if (!colour || (where === 'list' && !prefs.colourList)) return null;
  return { colour, stops: colourStops(colour, themeName(), reading) };
}

/** The colour behind a page, filling its parent; a new colour fades in over the old one. */
export function Backdrop({ reading, where = 'hymn', style }: { reading?: boolean; where?: 'hymn' | 'list'; style?: ViewStyle }) {
  const look = useHymnLook(reading, where);
  const id = look?.colour.id ?? '';
  const fade = useRef(new Animated.Value(1)).current;
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    if (!id || reduceMotionNow()) return fade.setValue(1);
    fade.setValue(0);
    Animated.timing(fade, { toValue: 1, duration: 260, useNativeDriver: true }).start();
  }, [id, fade]);
  if (!look) return null;
  return (
    <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, { opacity: fade }, style]}>
      <LinearGradient colors={look.stops as unknown as readonly [string, string, ...string[]]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
    </Animated.View>
  );
}
