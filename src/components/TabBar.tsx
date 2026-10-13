import React, { useEffect, useRef, useState } from 'react';
import { Animated, type LayoutChangeEvent, Pressable, StyleSheet, useWindowDimensions, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { tap } from '../lib/haptics';
import { C } from '../lib/theme';
import { Icon, type IconName } from './Icon';
import { Text } from './Text';
import { reduceMotionNow } from './ui';
import { type Key, useT } from '../lib/i18n';

/*
 * The SDA app's bottom bar: a frosted island inset from the screen's edges, with a green pill that
 * springs across to the tab you're on, with each tab's name under its icon.
 */

export const TAB_BAR_HEIGHT = 66;
const SIDE = 13;
const PAD = 6;
export const tabBarBottom = (insetBottom: number) => (insetBottom > 0 ? Math.max(insetBottom - 4, 12) : 12);
/** Room a list leaves at its end so its last row clears the bar. */
export const useTabBarSpace = () => TAB_BAR_HEIGHT + tabBarBottom(useSafeAreaInsets().bottom) + 24;

const TABS: Record<string, { icon: IconName; label: Key }> = {
  index: { icon: 'hymnal', label: 'tab.hymnal' },
  discover: { icon: 'sparkle', label: 'tab.discover' },
  favourites: { icon: 'heart', label: 'tab.favourites' },
  settings: { icon: 'settings', label: 'tab.settings' },
};

export function TabBar({ state, navigation }: any) {
  const t = useT();
  const insets = useSafeAreaInsets();
  const { width: screenW } = useWindowDimensions();
  const activeKey: string | undefined = state.routes[state.index]?.key;
  const [spots, setSpots] = useState<Record<string, { x: number; w: number }>>({});
  const spot = activeKey ? spots[activeKey] : undefined;
  const pillX = useRef(new Animated.Value(0)).current;
  const placed = useRef(false);
  useEffect(() => {
    if (!spot) return;
    if (!placed.current || reduceMotionNow()) {
      placed.current = true;
      pillX.setValue(spot.x);
      return;
    }
    const slide = Animated.spring(pillX, { toValue: spot.x, damping: 17, stiffness: 210, mass: 0.9, useNativeDriver: true });
    slide.start();
    return () => slide.stop();
  }, [spot?.x, pillX]);

  const barW = Math.min(screenW - SIDE * 2, 460);
  const light = C.blurTint === 'light';

  return (
    <View pointerEvents="box-none" style={{ position: 'absolute', left: 0, right: 0, bottom: tabBarBottom(insets.bottom), alignItems: 'center' }}>
      <View style={{ width: barW, height: TAB_BAR_HEIGHT, borderRadius: TAB_BAR_HEIGHT / 2, shadowColor: '#000', shadowOpacity: light ? 0.12 : 0.35, shadowRadius: 18, shadowOffset: { width: 0, height: 8 }, elevation: 12 }}>
        <BlurView intensity={60} tint={C.blurTint} style={{ flex: 1, borderRadius: TAB_BAR_HEIGHT / 2, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth, borderColor: light ? 'rgba(0,0,0,0.10)' : 'rgba(255,255,255,0.14)' }}>
          <View accessibilityRole="tablist" style={{ flex: 1, flexDirection: 'row', padding: PAD, backgroundColor: C.glass }}>
            {spot ? <Animated.View pointerEvents="none" style={{ position: 'absolute', left: 0, top: PAD, bottom: PAD, width: spot.w, borderRadius: TAB_BAR_HEIGHT / 2, backgroundColor: C.accent, transform: [{ translateX: pillX }] }} /> : null}
            {state.routes.map((route: any, i: number) => {
              const meta = TABS[route.name];
              if (!meta) return null;
              const on = state.index === i;
              const press = () => {
                tap('select');
                const e = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
                if (!on && !e.defaultPrevented) navigation.navigate(route.name, route.params);
              };
              const place = (e: LayoutChangeEvent) => {
                const { x, width } = e.nativeEvent.layout;
                setSpots((now) => (now[route.key]?.x === x && now[route.key]?.w === width ? now : { ...now, [route.key]: { x, w: width } }));
              };
              const color = on ? '#ffffff' : C.fg;
              return (
                <Pressable key={route.key} onPress={press} onLayout={place} accessibilityRole="tab" accessibilityState={{ selected: on }} accessibilityLabel={t(meta.label)} style={({ pressed }) => ({ flex: 1, alignItems: 'center', justifyContent: 'center', gap: 2, opacity: pressed && !on ? 0.55 : 1 })}>
                  <Icon name={meta.icon} size={23} color={color} weight={on ? 2.3 : 1.9} fill={on && meta.icon === 'heart'} />
                  <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.8} style={{ color, fontSize: 11, fontWeight: on ? '700' : '500' }}>{t(meta.label)}</Text>
                </Pressable>
              );
            })}
          </View>
        </BlurView>
      </View>
    </View>
  );
}
