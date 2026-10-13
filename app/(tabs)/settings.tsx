import React, { useMemo, useState } from 'react';
import { Alert, Image, Platform, Pressable, ScrollView, Share, View } from 'react-native';
import Constants from 'expo-constants';
import { useRouter } from 'expo-router';
import * as StoreReview from 'expo-store-review';
import { Band, SettingsLabel, SettingsRow } from '../../src/components/Settings';
import { useTabBarSpace } from '../../src/components/TabBar';
import { Text } from '../../src/components/Text';
import { Empty, Screen, SearchField, TabHeader, toast } from '../../src/components/ui';
import type { IconName } from '../../src/components/Icon';
import { Icon } from '../../src/components/Icon';
import { colourById } from '../../src/lib/colours';
import { HYMN_COUNT } from '../../src/lib/hymnal';
import { DEFAULT_PREFS, setPrefs, usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

type Row = { id: string; icon: IconName; title: string; value?: string; words?: string; onPress?: () => void; toggle?: boolean; onToggle?: (v: boolean) => void; danger?: boolean };
type Section = { label: string; rows: Row[] };

/** Settings, laid out as Instagram's "Settings and activity". */
export default function Settings() {
  const router = useRouter();
  const prefs = usePrefs();
  const bottom = useTabBarSpace();
  const [q, setQ] = useState('');

  const themeLabel = prefs.theme === 'system' ? 'System' : prefs.theme === 'dark' ? 'Dark' : 'Light';
  const sections: Section[] = [
    {
      label: 'Your hymnal',
      rows: [
        { id: 'fav', icon: 'heart', title: 'Favourites', value: String(prefs.favourites.length), words: 'saved hearts', onPress: () => router.navigate('/favourites') },
        { id: 'recent', icon: 'history', title: 'Recently viewed', value: String(prefs.recent.length), words: 'history recent', onPress: () => router.navigate('/recent') },
        { id: 'history', icon: 'clock', title: 'Hymn history', value: prefs.history ? 'On' : 'Off', words: 'recent remember clear', onPress: () => router.push('/prefs/history') },
      ],
    },
    {
      label: 'How hymns look',
      rows: [
        { id: 'bg', icon: 'palette', title: 'Hymn background', value: colourById(prefs.hymnColour)?.name ?? 'Default', words: 'colour color wallpaper theme', onPress: () => router.push('/prefs/background') },
        { id: 'reading', icon: 'font', title: 'Text and reading', value: `${prefs.textSize} pt, ${prefs.font === 'serif' ? 'serif' : 'sans'}`, words: 'size font serif spacing verse numbers refrain', onPress: () => router.push('/prefs/reading') },
      ],
    },
    {
      label: 'Your app and display',
      rows: [
        { id: 'theme', icon: 'moon', title: 'Appearance', value: themeLabel, words: 'dark light mode theme', onPress: () => router.push('/prefs/appearance') },
        { id: 'awake', icon: 'screen', title: 'Keep screen on', words: 'awake sleep lock', toggle: prefs.keepAwake, onToggle: (v) => setPrefs({ keepAwake: v }) },
        { id: 'haptics', icon: 'vibrate', title: 'Haptics', words: 'vibration feedback', toggle: prefs.haptics, onToggle: (v) => setPrefs({ haptics: v }) },
      ],
    },
    {
      label: 'More info and support',
      rows: [
        { id: 'share', icon: 'share', title: 'Share SDA Hymnal', words: 'invite friends', onPress: () => Share.share({ message: `SDA Hymnal: all ${HYMN_COUNT} hymns of the Seventh-day Adventist Hymnal, offline.` }).catch(() => {}) },
        ...(Platform.OS === 'web' ? [] : [{ id: 'rate', icon: 'star' as IconName, title: 'Rate the app', words: 'review store', onPress: () => StoreReview.requestReview().catch(() => toast("Can't open the store here")) }]),
        { id: 'about', icon: 'info', title: 'About', words: 'version mojo', onPress: () => router.push('/prefs/about') },
        { id: 'credits', icon: 'book', title: 'Licences and credits', words: 'copyright photos fonts hymnary', onPress: () => router.push('/prefs/credits') },
      ],
    },
    {
      label: 'Reset',
      rows: [
        {
          id: 'reset',
          icon: 'undo',
          title: 'Reset settings',
          words: 'default restore',
          danger: true,
          onPress: () =>
            Alert.alert('Reset settings?', 'Your favourites and recent hymns stay.', [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Reset', style: 'destructive', onPress: () => setPrefs((p) => ({ ...DEFAULT_PREFS, favourites: p.favourites, recent: p.recent })) },
            ]),
        },
      ],
    },
  ];

  const needle = q.trim().toLowerCase();
  const found = useMemo(() => (needle ? sections.flatMap((s) => s.rows).filter((r) => `${r.title} ${r.words ?? ''}`.toLowerCase().includes(needle)) : []), [needle, sections]);

  return (
    <Screen>
      <TabHeader title="Settings" />
      <ScrollView keyboardShouldPersistTaps="handled" keyboardDismissMode="on-drag" contentContainerStyle={{ paddingBottom: bottom }}>
        <SearchField value={q} onChangeText={setQ} placeholder="Search" label="Search settings" style={{ marginBottom: 6 }} />
        {needle ? (
          found.length ? (
            <View style={{ paddingTop: 6 }}>{found.map(({ id, ...r }) => <SettingsRow key={id} {...r} />)}</View>
          ) : (
            <Empty icon="search" title="No settings found" />
          )
        ) : (
          <>
            {/* The app's own card at the top, where Instagram has its Accounts Center. */}
            <Pressable onPress={() => router.push('/prefs/about')} accessibilityRole="button" accessibilityLabel="About SDA Hymnal" style={({ pressed }) => ({ marginHorizontal: 16, marginTop: 12, padding: 14, borderRadius: 16, backgroundColor: pressed ? C.surface2 : C.surface, flexDirection: 'row', alignItems: 'center', gap: 14 })}>
              <View style={{ width: 52, height: 52, borderRadius: 14, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center' }}>
                <Image source={require('../../assets/sda-logo-solid-white.png')} style={{ width: 34, height: 30 }} resizeMode="contain" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ color: C.fg, fontSize: 17, fontWeight: '700' }}>SDA Hymnal</Text>
                <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 2 }}>{HYMN_COUNT} hymns, works offline</Text>
              </View>
              <Icon name="right" size={17} color={C.fg2} weight={2} />
            </Pressable>
            {sections.map((s, i) => (
              <View key={s.label}>
                {i > 0 ? <Band /> : <View style={{ height: 6 }} />}
                <SettingsLabel>{s.label}</SettingsLabel>
                {s.rows.map(({ id, ...r }) => (
                  <SettingsRow key={id} {...r} />
                ))}
              </View>
            ))}
            <Band />
            <View style={{ alignItems: 'center', paddingTop: 22, gap: 4 }}>
              <Text style={{ color: C.fg3, fontSize: 13 }}>by</Text>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Image source={require('../../assets/mojo.png')} style={{ width: 18, height: 20 }} resizeMode="contain" />
                <Text style={{ color: '#1fbf5a', fontSize: 17, fontWeight: '700' }}>Mojo</Text>
              </View>
              <Text style={{ color: C.fg3, fontSize: 12.5, marginTop: 4 }}>Version {Constants.expoConfig?.version ?? '1.0.0'}</Text>
            </View>
          </>
        )}
      </ScrollView>
    </Screen>
  );
}
