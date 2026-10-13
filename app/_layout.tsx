import React, { useCallback, useEffect, useState } from 'react';
import { useColorScheme, View } from 'react-native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import * as SystemUI from 'expo-system-ui';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { LaunchCover } from '../src/components/LaunchCover';
import { APP_FONT_FILES } from '../src/components/Text';
import { ToastOutlet } from '../src/components/ui';
import { loadPrefs, usePrefs } from '../src/lib/prefs';
import { applyTheme, C, type ThemeName } from '../src/lib/theme';

SplashScreen.preventAutoHideAsync().catch(() => {});

export default function RootLayout() {
  const [fonts, fontError] = useFonts(APP_FONT_FILES);
  const [ready, setReady] = useState(false);
  const [cover, setCover] = useState(true);
  const prefs = usePrefs();
  const system = useColorScheme();

  useEffect(() => {
    loadPrefs().finally(() => setReady(true));
  }, []);

  // The theme: the phone's (System) or the one chosen in Settings. Set before anything below draws.
  const theme: ThemeName = prefs.theme === 'system' ? (system === 'dark' ? 'dark' : 'white') : prefs.theme;
  applyTheme(theme);

  useEffect(() => {
    SystemUI.setBackgroundColorAsync(C.bg).catch(() => {});
  }, [theme]);

  // A font that won't load leaves the phone's own face, rather than the splash screen forever.
  const go = (fonts || !!fontError) && ready;
  useEffect(() => {
    if (go) SplashScreen.hideAsync().catch(() => {});
  }, [go]);
  const done = useCallback(() => setCover(false), []);

  if (!go) return null;
  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: C.bg }}>
      {/* Keyed by theme: every screen draws again in the new colours. */}
      <View key={theme} style={{ flex: 1 }}>
        <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: C.bg }, animation: 'slide_from_right' }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="hymn/[number]" />
          <Stack.Screen name="part/[index]" />
          <Stack.Screen name="prefs" />
        </Stack>
      </View>
      <ToastOutlet />
      {cover ? <LaunchCover onDone={done} /> : null}
    </GestureHandlerRootView>
  );
}
