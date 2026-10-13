import React from 'react';
import { Image, ScrollView, View } from 'react-native';
import Constants from 'expo-constants';
import { Band, SettingsRow } from '../../src/components/Settings';
import { serif, Text } from '../../src/components/Text';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { HYMN_COUNT, HYMNS } from '../../src/lib/hymnal';
import { useT } from '../../src/lib/i18n';
import { C } from '../../src/lib/theme';

export default function About() {
  const t = useT();
  const withWords = HYMNS.filter((h) => h.lyrics).length;
  return (
    <Screen>
      <ScreenHeader title={t('settings.about')} />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <View style={{ alignItems: 'center', paddingTop: 18, paddingBottom: 24, gap: 6 }}>
          <View style={{ width: 96, height: 96, borderRadius: 24, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center' }}>
            <Image source={require('../../assets/sda-logo-solid-white.png')} style={{ width: 62, height: 55 }} resizeMode="contain" accessibilityLabel="Seventh-day Adventist" />
          </View>
          <Text style={[serif(600), { color: C.fg, fontSize: 26, marginTop: 12 }]}>SDA Hymnal</Text>
          <Text style={{ color: C.fg2, fontSize: 14.5 }}>{t('about.version', { v: Constants.expoConfig?.version ?? '1.0.0' })}</Text>
        </View>
        <SettingsRow icon="hymnal" title={t('about.hymns')} value={String(HYMN_COUNT)} />
        <SettingsRow icon="book" title={t('about.words')} value={String(withWords)} />
        <SettingsRow icon="globe" title={t('about.offline')} value={t('about.yes')} />
        <Band />
        <View style={{ alignItems: 'center', paddingTop: 24, gap: 4 }}>
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
