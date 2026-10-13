import React from 'react';
import { ScrollView } from 'react-native';
import { Icon } from '../../src/components/Icon';
import { Caption, ChoiceRow } from '../../src/components/Settings';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { useT } from '../../src/lib/i18n';
import { setPrefs, usePrefs, type ThemeChoice } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

export default function Appearance() {
  const t = useT();
  const prefs = usePrefs();
  const choices: { id: ThemeChoice; title: string; icon: 'mac' | 'sun' | 'moon' }[] = [
    { id: 'system', title: t('settings.system'), icon: 'mac' },
    { id: 'white', title: t('settings.light'), icon: 'sun' },
    { id: 'dark', title: t('settings.dark'), icon: 'moon' },
  ];
  return (
    <Screen>
      <ScreenHeader title={t('settings.appearance')} />
      <ScrollView>
        {choices.map((c) => (
          <ChoiceRow key={c.id} title={c.title} on={prefs.theme === c.id} onPress={() => setPrefs({ theme: c.id })} left={<Icon name={c.icon} size={24} color={C.fg} weight={1.8} />} />
        ))}
        <Caption>{t('settings.systemSub')}</Caption>
      </ScrollView>
    </Screen>
  );
}
