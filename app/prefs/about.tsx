import React from 'react';
import { Image, ScrollView, View } from 'react-native';
import Constants from 'expo-constants';
import { useRouter } from 'expo-router';
import { Band, SettingsRow } from '../../src/components/Settings';
import { Text } from '../../src/components/Text';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { HYMN_COUNT, HYMNS } from '../../src/lib/hymnal';
import { C, themeName } from '../../src/lib/theme';

export default function About() {
  const router = useRouter();
  const withWords = HYMNS.filter((h) => h.lyrics).length;
  return (
    <Screen>
      <ScreenHeader title="About" />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <View style={{ alignItems: 'center', paddingTop: 18, paddingBottom: 22, gap: 6 }}>
          <Image source={themeName() === 'dark' ? require('../../assets/splash-logo-dark.png') : require('../../assets/splash-logo.png')} style={{ width: 96, height: 86 }} resizeMode="contain" />
          <Text style={{ color: C.fg, fontSize: 22, fontWeight: '800', marginTop: 10 }}>SDA Hymnal</Text>
          <Text style={{ color: C.fg2, fontSize: 14.5 }}>Version {Constants.expoConfig?.version ?? '1.0.0'}</Text>
        </View>
        <SettingsRow icon="hymnal" title="Hymns" value={String(HYMN_COUNT)} />
        <SettingsRow icon="book" title="With words in the app" value={String(withWords)} />
        <SettingsRow icon="globe" title="Works offline" value="Yes" />
        <Band />
        <SettingsRow icon="book" title="Licences and credits" onPress={() => router.push('/prefs/credits')} />
        <Band />
        <View style={{ alignItems: 'center', paddingTop: 22, gap: 4 }}>
          <Text style={{ color: C.fg3, fontSize: 13 }}>by</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Image source={require('../../assets/mojo.png')} style={{ width: 18, height: 20 }} resizeMode="contain" />
            <Text style={{ color: '#1fbf5a', fontSize: 17, fontWeight: '700' }}>Mojo</Text>
          </View>
        </View>
      </ScrollView>
    </Screen>
  );
}
