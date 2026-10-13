import React, { useState } from 'react';
import { PixelRatio, StyleSheet, View, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';

/*
 * The app's photographs: real photos (the same registry as the SDA app's, free to use with no credit
 * on the photo), loaded at the size they're drawn and then kept on the phone. Each has a `tone`, a
 * gradient in its own colours painted underneath: it shows while the photo loads and instead of it
 * offline, so a banner or card always looks finished.
 */
export type PhotoEntry = { id: string; focus: string; tone: readonly [string, string, ...string[]] };

export const PHOTOS = {
  // A blue hymnbook, "Hymns of Faith".
  tileHymnal: { id: 'photo-1536777525605-e146b6cef617', focus: '50% 50%', tone: ['#6f8fb3', '#34506e', '#16222f'] },
  // Hands holding an open songbook.
  hymnal: { id: 'photo-1482627988233-7c68311232ea', focus: '50% 45%', tone: ['#8a2440', '#46205a', '#1c1430'] },
  // Mountain ridges under a warm sky.
  emptyExplore: { id: 'photo-1604223190546-a43e4c7f29d7', focus: '50% 50%', tone: ['#f3a65a', '#a9584a', '#2e2340'] },
  // A leather-bound hymnal, open.
  hymnOfDay: { id: 'photo-1745000769767-2198d91b750b', focus: '50% 50%', tone: ['#8a5a3b', '#4a2c1f'] },
  // An upright piano in a church.
  emptyMusic: { id: 'photo-1509343456624-5e034c8f321c', focus: '50% 50%', tone: ['#8a6a4e', '#3f2e22', '#141010'] },
  // Pews and the cross in a chapel, in blue light.
  service: { id: 'photo-1574642631319-ee4e726c5888', focus: '50% 45%', tone: ['#24418c', '#101a38'] },
  // Candles burning in the dark.
  prayer: { id: 'photo-1694588063491-b6dcddc85c97', focus: '50% 50%', tone: ['#3d2712', '#120b06'] },
  // An open Bible.
  bibleStudy: { id: 'photo-1469228252629-cbe7cb7db2c8', focus: '50% 50%', tone: ['#7b6a5a', '#3b3440'] },
  // A hand writing in a notebook.
  emptyWrite: { id: 'photo-1456324504439-367cee3b3c32', focus: '50% 50%', tone: ['#cfcac2', '#8f8a83', '#3b3936'] },
} satisfies Record<string, PhotoEntry>;

export type PhotoKey = keyof typeof PHOTOS;

export function Photo({ photo, width, style, children }: { photo: PhotoEntry | PhotoKey; width: number; style?: ViewStyle; children?: React.ReactNode }) {
  const p = typeof photo === 'string' ? PHOTOS[photo] : photo;
  const [off, setOff] = useState(false);
  const pixels = PixelRatio.getPixelSizeForLayoutSize(Math.max(1, width));
  const ask = pixels <= 800 ? 800 : pixels <= 1600 ? 1600 : 2400;
  const [x = '50%', y = '50%'] = p.focus.split(/\s+/);
  return (
    <View style={[{ overflow: 'hidden', backgroundColor: p.tone[p.tone.length - 1] }, style]}>
      <LinearGradient pointerEvents="none" colors={p.tone} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
      {off ? null : (
        <Image
          source={{ uri: `https://images.unsplash.com/${p.id}?auto=format&fit=crop&w=${ask}&q=80` }}
          contentFit="cover"
          contentPosition={{ left: x, top: y }}
          cachePolicy="memory-disk"
          transition={200}
          onError={() => setOff(true)}
          style={StyleSheet.absoluteFill}
          accessibilityIgnoresInvertColors
        />
      )}
      {children}
    </View>
  );
}
