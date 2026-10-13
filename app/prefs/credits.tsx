import React from 'react';
import { ScrollView } from 'react-native';
import * as WebBrowser from 'expo-web-browser';
import { Band, Caption, SettingsLabel, SettingsRow } from '../../src/components/Settings';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { useT } from '../../src/lib/i18n';

const open = (url: string) => WebBrowser.openBrowserAsync(url).catch(() => {});

export default function Credits() {
  const t = useT();
  return (
    <Screen>
      <ScreenHeader title={t('settings.credits')} />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <SettingsLabel>{t('credits.hymns')}</SettingsLabel>
        <Caption>{t('credits.hymnsBody')}</Caption>
        <SettingsRow icon="globe" title="Hymnary.org" onPress={() => open('https://hymnary.org/hymnal/SDAH1985')} />
        <Band />
        <SettingsLabel>{t('credits.photos')}</SettingsLabel>
        <Caption>{t('credits.photosBody')}</Caption>
        <Band />
        <SettingsLabel>{t('credits.fonts')}</SettingsLabel>
        <SettingsRow icon="font" title="Newsreader" sub="Production Type, SIL Open Font License" onPress={() => open('https://fonts.google.com/specimen/Newsreader')} />
        <SettingsRow icon="font" title="Plus Jakarta Sans" sub="Tokotype, SIL Open Font License" onPress={() => open('https://fonts.google.com/specimen/Plus+Jakarta+Sans')} />
        <Band />
        <SettingsLabel>{t('credits.logo')}</SettingsLabel>
        <Caption>{t('credits.logoBody')}</Caption>
      </ScrollView>
    </Screen>
  );
}
