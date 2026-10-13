import React, { useMemo, useRef } from 'react';
import { Animated, StyleSheet, useWindowDimensions, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { C } from '../lib/theme';
import { useHymnLook } from './Backdrop';
import type { IconName } from './Icon';
import { Photo, type PhotoEntry } from './Photo';
import { serif, Text } from './Text';
import { RoundButton, SearchField, useBarStyle } from './ui';

/*
 * The SDA app's photo banner, as on its Hymnal page: a real photo from the top of the screen, dark at
 * the bottom, the page's name in big white letters with one short line under it. It is drawn over the
 * list, not inside it, so the search field under it stays put. As the list scrolls the banner slides up
 * until only a 56-point bar of the photo is left, where the name fades in small.
 */

export const HERO_BODY = 186;
export const HERO_BAR = 56;
export const HERO_SEARCH = 56;

export function useHeroScroll(): { scroll: Animated.Value; onScroll: (...args: any[]) => void } {
  const scroll = useRef(new Animated.Value(0)).current;
  const onScroll = useMemo(() => Animated.event([{ nativeEvent: { contentOffset: { y: scroll } } }], { useNativeDriver: true }), [scroll]);
  return { scroll, onScroll };
}

export function useHeroLayout(below = 0): { paddingTop: number } {
  const insets = useSafeAreaInsets();
  return { paddingTop: insets.top + HERO_BODY + below };
}

/** A round see-through button on the photo, white. */
export function HeroButton({ name, label, onPress }: { name: IconName; label: string; onPress?: () => void }) {
  return <RoundButton name={name} label={label} onPress={onPress} bg="rgba(255,255,255,0.2)" color="#ffffff" />;
}

export function HeroSearch({ value, onChangeText, placeholder, label }: { value: string; onChangeText: (s: string) => void; placeholder?: string; label?: string }) {
  return (
    <View style={{ height: HERO_SEARCH, justifyContent: 'center' }}>
      <SearchField value={value} onChangeText={onChangeText} placeholder={placeholder} label={label} />
    </View>
  );
}

export function PhotoHero({ photo, title, line, scroll, left, right, below, belowHeight = 0 }: {
  photo: PhotoEntry;
  title: string;
  line?: string;
  scroll: Animated.Value;
  left?: React.ReactNode;
  right?: React.ReactNode;
  below?: React.ReactNode;
  belowHeight?: number;
}) {
  const insets = useSafeAreaInsets();
  const { width, height: screenH } = useWindowDimensions();
  const look = useHymnLook(false, 'list');
  // White clock and battery over the photo, in both themes.
  useBarStyle('light');
  const full = insets.top + HERO_BODY;
  const range = HERO_BODY - HERO_BAR;
  const lift = useMemo(() => scroll.interpolate({ inputRange: [0, range], outputRange: [0, -range], extrapolate: 'clamp' }), [scroll, range]);
  const stretch = useMemo(() => scroll.interpolate({ inputRange: [-120, 0], outputRange: [1.35, 1], extrapolate: 'clamp' }), [scroll]);
  const bigFade = useMemo(() => scroll.interpolate({ inputRange: [0, range * 0.55], outputRange: [1, 0], extrapolate: 'clamp' }), [scroll, range]);
  const smallFade = useMemo(() => scroll.interpolate({ inputRange: [range * 0.6, range], outputRange: [0, 1], extrapolate: 'clamp' }), [scroll, range]);
  // The band under the photo moves up with it; its slice of the colour moves down as far, so it meets the backdrop without a seam.
  const unlift = useMemo(() => scroll.interpolate({ inputRange: [0, range], outputRange: [0, range], extrapolate: 'clamp' }), [scroll, range]);

  return (
    <View pointerEvents="box-none" style={{ position: 'absolute', top: 0, left: 0, right: 0 }}>
      <Animated.View pointerEvents="box-none" style={{ transform: [{ translateY: lift }] }}>
        <View pointerEvents="box-none" style={{ height: full, backgroundColor: '#0b1014', overflow: 'hidden' }}>
          <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, { transform: [{ scale: stretch }] }]}>
            <Photo photo={photo} width={width} style={StyleSheet.absoluteFillObject} />
          </Animated.View>
          <LinearGradient pointerEvents="none" colors={['rgba(0,0,0,0.42)', 'rgba(0,0,0,0.04)', 'rgba(0,0,0,0.22)', 'rgba(0,0,0,0.84)']} locations={[0, 0.32, 0.56, 1]} style={StyleSheet.absoluteFill} />
          <Animated.View pointerEvents="none" style={{ position: 'absolute', left: 16, right: 16, bottom: 16, opacity: bigFade }}>
            <Text accessibilityRole="header" numberOfLines={2} adjustsFontSizeToFit minimumFontScale={0.8} style={{ ...serif(600), color: '#ffffff', fontSize: 40, lineHeight: 44, letterSpacing: -0.6, textShadowColor: 'rgba(0,0,0,0.35)', textShadowRadius: 10, textShadowOffset: { width: 0, height: 1 } }}>
              {title}
            </Text>
            {line ? <Text numberOfLines={1} style={{ color: 'rgba(255,255,255,0.84)', fontSize: 14.5, fontWeight: '500', marginTop: 4 }}>{line}</Text> : null}
          </Animated.View>
        </View>
        {below ? (
          <View style={{ height: belowHeight, backgroundColor: C.bg, justifyContent: 'center', overflow: 'hidden' }}>
            {look ? (
              <Animated.View pointerEvents="none" style={{ position: 'absolute', left: 0, width, top: -full, height: screenH, transform: [{ translateY: unlift }] }}>
                <LinearGradient colors={look.stops as unknown as readonly [string, string, ...string[]]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
              </Animated.View>
            ) : null}
            {below}
          </View>
        ) : null}
      </Animated.View>
      <View pointerEvents="auto" style={{ position: 'absolute', top: insets.top, left: 0, right: 0, height: HERO_BAR, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16 }}>
        <View pointerEvents="box-none" style={{ minWidth: 96, flexShrink: 0, flexDirection: 'row', gap: 8 }}>{left}</View>
        <Animated.View pointerEvents="none" style={{ flex: 1, opacity: smallFade }}>
          <Text numberOfLines={1} style={{ ...serif(600), color: '#ffffff', fontSize: 21, textAlign: 'center', paddingHorizontal: 8 }}>{title}</Text>
        </Animated.View>
        <View pointerEvents="box-none" style={{ minWidth: 96, flexShrink: 0, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', gap: 8 }}>{right}</View>
      </View>
    </View>
  );
}
