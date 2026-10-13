import React from 'react';
import { Image, Linking, Platform, Pressable, ScrollView, Share, View } from 'react-native';
import Constants from 'expo-constants';
import { useRouter } from 'expo-router';
import * as StoreReview from 'expo-store-review';
import { Icon } from '../../src/components/Icon';
import { Band, SettingsRow } from '../../src/components/Settings';
import { useTabBarSpace } from '../../src/components/TabBar';
import { serif, Text } from '../../src/components/Text';
import { Screen, TabHeader, toast } from '../../src/components/ui';
import { HYMN_COUNT } from '../../src/lib/hymnal';
import { LANGUAGE_NAMES, useT } from '../../src/lib/i18n';
import { usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

/** Settings, kept short: the look, the language, favourites, and the app itself. */
export default function Settings() {
  const t = useT();
  const router = useRouter();
  const prefs = usePrefs();
  const bottom = useTabBarSpace();
  const theme = prefs.theme === 'system' ? t('settings.system') : prefs.theme === 'dark' ? t('settings.dark') : t('settings.light');

  const rate = async () => {
    try {
      if (await StoreReview.isAvailableAsync()) return await StoreReview.requestReview();
      const url = StoreReview.storeUrl();
      if (url) return await Linking.openURL(url);
      toast(t('settings.rateFailed'));
    } catch {
      toast(t('settings.rateFailed'));
    }
  };

  return (
    <Screen>
      <TabHeader title={t('settings.title')} />
      <ScrollView contentContainerStyle={{ paddingBottom: bottom }}>
        {/* The app's own card at the top. */}
        <Pressable onPress={() => router.push('/prefs/about')} accessibilityRole="button" accessibilityLabel={t('settings.about')} style={({ pressed }) => ({ marginHorizontal: 16, marginTop: 6, marginBottom: 10, padding: 16, borderRadius: 20, backgroundColor: pressed ? C.surface2 : C.surface, flexDirection: 'row', alignItems: 'center', gap: 14 })}>
          <View style={{ width: 56, height: 56, borderRadius: 15, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center' }}>
            <Image source={require('../../assets/sda-logo-solid-white.png')} style={{ width: 36, height: 32 }} resizeMode="contain" />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[serif(600), { color: C.fg, fontSize: 21 }]}>SDA Hymnal</Text>
            <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 2 }}>{t('about.version', { v: Constants.expoConfig?.version ?? '1.0.0' })}</Text>
          </View>
          <Icon name="right" size={17} color={C.fg2} weight={2} />
        </Pressable>

        <SettingsRow icon="moon" title={t('settings.appearance')} value={theme} onPress={() => router.push('/prefs/appearance')} />
        <SettingsRow icon="globe" title={t('settings.language')} value={LANGUAGE_NAMES[prefs.language]} onPress={() => router.push('/prefs/language')} />
        <SettingsRow icon="heart" title={t('settings.favourites')} value={String(prefs.favourites.length)} onPress={() => router.navigate('/favourites')} />
        <Band />
        <SettingsRow icon="share" title={t('settings.share')} onPress={() => Share.share({ message: t('settings.shareMessage', { n: HYMN_COUNT }) }).catch(() => {})} />
        {Platform.OS !== 'web' ? <SettingsRow icon="star" title={t('settings.rate')} onPress={rate} /> : null}
        <Band />
        <SettingsRow icon="info" title={t('settings.about')} onPress={() => router.push('/prefs/about')} />
        <SettingsRow icon="book" title={t('settings.credits')} onPress={() => router.push('/prefs/credits')} />

        <View style={{ alignItems: 'center', paddingTop: 30, gap: 4 }}>
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
