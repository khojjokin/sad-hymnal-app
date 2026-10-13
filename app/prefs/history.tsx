import React from 'react';
import { Alert, ScrollView } from 'react-native';
import { Band, SettingsRow } from '../../src/components/Settings';
import { Screen, ScreenHeader, toast } from '../../src/components/ui';
import { setPrefs, usePrefs } from '../../src/lib/prefs';

export default function History() {
  const prefs = usePrefs();
  const clear = () =>
    Alert.alert('Clear recent hymns?', undefined, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Clear', style: 'destructive', onPress: () => { setPrefs({ recent: [] }); toast('Recent hymns cleared'); } },
    ]);
  return (
    <Screen>
      <ScreenHeader title="Hymn history" />
      <ScrollView>
        <SettingsRow icon="history" title="Keep recent hymns" sub="Kept on this phone only" toggle={prefs.history} onToggle={(v) => setPrefs(v ? { history: true } : { history: false, recent: [] })} />
        {prefs.recent.length ? (
          <>
            <Band />
            <SettingsRow icon="trash" title={`Clear ${prefs.recent.length} recent hymn${prefs.recent.length === 1 ? '' : 's'}`} danger onPress={clear} />
          </>
        ) : null}
      </ScrollView>
    </Screen>
  );
}
