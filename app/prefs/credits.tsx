import React from 'react';
import { ScrollView } from 'react-native';
import * as WebBrowser from 'expo-web-browser';
import { photoCreditUrl, PHOTOS } from '../../src/components/Photo';
import { Band, Caption, SettingsLabel, SettingsRow } from '../../src/components/Settings';
import { Screen, ScreenHeader } from '../../src/components/ui';

const open = (url: string) => WebBrowser.openBrowserAsync(url).catch(() => {});

export default function Credits() {
  return (
    <Screen>
      <ScreenHeader title="Licences and credits" />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <SettingsLabel>Hymns</SettingsLabel>
        <Caption>Hymns are numbered as in the Seventh-day Adventist Hymnal (1985). The app shows the words of hymns in the public domain; for the rest it shows the title and links to Hymnary.org. Tunes and arrangements belong to their publishers and aren't in the app.</Caption>
        <SettingsRow icon="globe" title="Hymnary.org" onPress={() => open('https://hymnary.org/hymnal/SDAH1985')} />
        <Band />
        <SettingsLabel>Photo</SettingsLabel>
        <SettingsRow icon="image" title={`Hymnal banner by ${PHOTOS.hymnal.name}`} sub="Unsplash License" onPress={() => open(photoCreditUrl(PHOTOS.hymnal))} />
        <Band />
        <SettingsLabel>Fonts</SettingsLabel>
        <SettingsRow icon="font" title="Newsreader" sub="Production Type, SIL Open Font License" onPress={() => open('https://fonts.google.com/specimen/Newsreader')} />
        <SettingsRow icon="font" title="Plus Jakarta Sans" sub="Tokotype, SIL Open Font License" onPress={() => open('https://fonts.google.com/specimen/Plus+Jakarta+Sans')} />
        <Band />
        <SettingsLabel>Logo</SettingsLabel>
        <Caption>The Seventh-day Adventist logo is a trademark of the General Conference of Seventh-day Adventists.</Caption>
      </ScrollView>
    </Screen>
  );
}
