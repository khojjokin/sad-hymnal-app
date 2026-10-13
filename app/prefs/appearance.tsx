import React from 'react';
import { ScrollView } from 'react-native';
import { Icon } from '../../src/components/Icon';
import { Caption, ChoiceRow } from '../../src/components/Settings';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { setPrefs, usePrefs, type ThemeChoice } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

const CHOICES: { id: ThemeChoice; title: string; icon: 'mac' | 'sun' | 'moon' }[] = [
  { id: 'system', title: 'System default', icon: 'mac' },
  { id: 'white', title: 'Light', icon: 'sun' },
  { id: 'dark', title: 'Dark', icon: 'moon' },
];

export default function Appearance() {
  const prefs = usePrefs();
  return (
    <Screen>
      <ScreenHeader title="Appearance" />
      <ScrollView>
        {CHOICES.map((c) => (
          <ChoiceRow key={c.id} title={c.title} on={prefs.theme === c.id} onPress={() => setPrefs({ theme: c.id })} left={<Icon name={c.icon} size={24} color={C.fg} weight={1.8} />} />
        ))}
        <Caption>System default follows your phone's light or dark setting.</Caption>
      </ScrollView>
    </Screen>
  );
}
