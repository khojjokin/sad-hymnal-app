import React, { useEffect, useRef, useState } from 'react';
import { Animated, Easing, Image, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { C, themeName } from '../lib/theme';
import { Text } from './Text';
import { reduceMotionNow } from './ui';

/*
 * The opening screen. The phone's own splash (app.json) shows the SDA logo alone; this takes over in
 * the same place, so the logo doesn't jump, adds "by Mojo" at the bottom as Instagram does "from Meta",
 * then fades away to the hymnal.
 */
const LOGO_W = 170;

export function LaunchCover({ onDone }: { onDone: () => void }) {
  const insets = useSafeAreaInsets();
  const fade = useRef(new Animated.Value(1)).current;
  const byline = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(1)).current;
  const [gone, setGone] = useState(false);
  const dark = themeName() === 'dark';

  useEffect(() => {
    const quick = reduceMotionNow();
    const run = Animated.sequence([
      Animated.timing(byline, { toValue: 1, duration: quick ? 0 : 360, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
      Animated.delay(quick ? 500 : 750),
      Animated.parallel([
        Animated.timing(fade, { toValue: 0, duration: quick ? 150 : 320, easing: Easing.in(Easing.quad), useNativeDriver: true }),
        Animated.timing(scale, { toValue: quick ? 1 : 1.06, duration: 320, useNativeDriver: true }),
      ]),
    ]);
    run.start(() => {
      setGone(true);
      onDone();
    });
    return () => run.stop();
  }, [byline, fade, scale, onDone]);

  if (gone) return null;
  return (
    <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, { backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center', opacity: fade, zIndex: 10 }]}>
      <Animated.View style={{ transform: [{ scale }] }}>
        <Image source={dark ? require('../../assets/splash-logo-dark.png') : require('../../assets/splash-logo.png')} style={{ width: LOGO_W, height: LOGO_W * (280 / 314) }} resizeMode="contain" accessibilityLabel="Seventh-day Adventist" />
      </Animated.View>
      <Animated.View style={{ position: 'absolute', bottom: insets.bottom + 36, alignItems: 'center', opacity: byline, transform: [{ translateY: byline.interpolate({ inputRange: [0, 1], outputRange: [8, 0] }) }] }}>
        <Text style={{ color: C.fg3, fontSize: 13.5, fontWeight: '500', letterSpacing: 0.3 }}>by</Text>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 2 }}>
          <Image source={require('../../assets/mojo.png')} style={{ width: 20, height: 22 }} resizeMode="contain" />
          <Text style={{ color: '#1fbf5a', fontSize: 19, fontWeight: '700', letterSpacing: 0.2 }}>Mojo</Text>
        </View>
      </Animated.View>
    </Animated.View>
  );
}
