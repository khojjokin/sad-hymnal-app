import React, { forwardRef } from 'react';
import { Image, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colourById, colourStops } from '../lib/colours';
import type { Hymn } from '../lib/hymnal';
import { getPrefs } from '../lib/prefs';
import { C, themeName } from '../lib/theme';
import { SERIF, Text } from './Text';

/*
 * The picture a hymn is shared as: 4 by 5, like an Instagram post. The hymn's background colour (or
 * the app's green on Default), the SDA logo and the number at the top, the title, one verse, and the
 * app's name at the foot. Drawn off screen and captured by react-native-view-shot.
 */
export const CARD_W = 360;
export const CARD_H = 450;

export const ShareCard = forwardRef<View, { hymn: Hymn; verse: string }>(function ShareCard({ hymn, verse }, ref) {
  const prefs = getPrefs();
  const colour = colourById(prefs.hymnColour);
  const onColour = !!colour;
  const stops = colour ? colourStops(colour, themeName(), true) : ['#1fbf5a', '#0d7a3a', '#0b3d22'];
  const fg = onColour ? C.fg : '#ffffff';
  const fg2 = onColour ? C.fg2 : 'rgba(255,255,255,0.82)';
  const dark = onColour ? themeName() === 'dark' : true;
  const lines = verse.split('\n');
  const size = lines.length > 6 ? 15 : 17;
  return (
    <View ref={ref} collapsable={false} style={{ width: CARD_W, height: CARD_H, overflow: 'hidden' }}>
      <LinearGradient colors={stops as unknown as readonly [string, string, ...string[]]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
      <View style={{ flex: 1, padding: 28 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
          <Image source={dark ? require('../../assets/splash-logo-dark.png') : require('../../assets/splash-logo.png')} style={{ width: 30, height: 27 }} resizeMode="contain" />
          <Text style={{ color: fg2, fontSize: 13, fontWeight: '700', letterSpacing: 1.4, textTransform: 'uppercase' }}>Hymn {hymn.number}</Text>
        </View>
        <Text numberOfLines={2} style={{ color: fg, fontSize: 26, lineHeight: 31, fontWeight: '800', marginTop: 22, letterSpacing: -0.3 }}>{hymn.title}</Text>
        <View style={{ flex: 1, justifyContent: 'center' }}>
          <Text numberOfLines={10} style={{ color: fg, fontSize: size, lineHeight: Math.round(size * 1.5), fontFamily: SERIF }}>{verse}</Text>
        </View>
        <View style={{ flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <Text numberOfLines={1} style={{ color: fg2, fontSize: 13, flex: 1, paddingRight: 12 }}>{hymn.author}</Text>
          <Text style={{ color: fg2, fontSize: 13, fontWeight: '700' }}>SDA Hymnal</Text>
        </View>
      </View>
    </View>
  );
});
