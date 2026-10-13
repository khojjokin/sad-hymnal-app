import React from 'react';
import { ScrollView } from 'react-native';
import { Caption, ChoiceRow } from '../../src/components/Settings';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { LANGUAGE_NAMES, useT } from '../../src/lib/i18n';
import { LANGUAGES, setPrefs, usePrefs } from '../../src/lib/prefs';

export default function Language() {
  const t = useT();
  const prefs = usePrefs();
  return (
    <Screen>
      <ScreenHeader title={t('settings.language')} />
      <ScrollView>
        {LANGUAGES.map((l) => (
          <ChoiceRow key={l} title={LANGUAGE_NAMES[l]} on={prefs.language === l} onPress={() => setPrefs({ language: l })} />
        ))}
        <Caption>{t('settings.languageSub')}</Caption>
      </ScrollView>
    </Screen>
  );
}
