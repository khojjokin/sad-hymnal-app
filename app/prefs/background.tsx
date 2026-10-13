import React from 'react';
import { ScrollView, View } from 'react-native';
import { chooseColour, HymnPreview, Swatches } from '../../src/components/ColourSheet';
import { Band, SettingsLabel, SettingsRow } from '../../src/components/Settings';
import { Text } from '../../src/components/Text';
import { Screen, ScreenHeader } from '../../src/components/ui';
import { colourById, colourStops } from '../../src/lib/colours';
import { setPrefs, usePrefs } from '../../src/lib/prefs';
import { C, themeName } from '../../src/lib/theme';

/** The colour behind the hymns, chosen here or from the palette on any hymn. */
export default function Background() {
  const prefs = usePrefs();
  const colour = colourById(prefs.hymnColour);
  const stops = colour ? colourStops(colour, themeName(), true) : null;
  return (
    <Screen>
      <ScreenHeader title="Hymn background" />
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <View style={{ paddingHorizontal: 20, paddingTop: 8 }}>
          <HymnPreview stops={stops} height={170} />
          <Text style={{ color: C.fg2, fontSize: 14, textAlign: 'center', marginTop: 10 }} accessibilityLiveRegion="polite">
            {colour?.name ?? 'Default'}
          </Text>
        </View>
        <View style={{ paddingHorizontal: 12, paddingTop: 18 }}>
          <Swatches chosen={prefs.hymnColour} onChoose={chooseColour} />
        </View>
        <Band />
        <SettingsLabel>Where it shows</SettingsLabel>
        <SettingsRow icon="hymnal" title="Behind the hymnal list too" toggle={prefs.colourList} onToggle={(v) => setPrefs({ colourList: v })} />
      </ScrollView>
    </Screen>
  );
}
