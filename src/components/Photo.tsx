import React, { useState } from 'react';
import { PixelRatio, StyleSheet, View, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';

/*
 * Real photographs from Unsplash (free under the Unsplash License, no credit line needed on the photo;
 * the photographers are listed in Settings › Licences and credits). Each has a `tone`, a gradient in
 * its own colours, painted underneath: it shows while the photo loads and instead of it offline, so the
 * banner always looks finished. expo-image keeps the photo on the phone after the first time.
 */
export type PhotoEntry = { id: string; name: string; user: string; focus: string; tone: readonly [string, string, ...string[]] };

export const PHOTOS = {
  // The SDA app's Hymnal banner: hands holding an open songbook (unsplash.com/photos/rU4kvQKjG2o).
  hymnal: { id: 'photo-1482627988233-7c68311232ea', name: 'David Beale', user: 'davidbeale', focus: '50% 45%', tone: ['#8a2440', '#46205a', '#1c1430'] },
} satisfies Record<string, PhotoEntry>;

export const photoCreditUrl = (p: PhotoEntry) => `https://unsplash.com/@${p.user}?utm_source=sda_hymnal&utm_medium=referral`;

export function Photo({ photo, width, style }: { photo: PhotoEntry; width: number; style?: ViewStyle }) {
  const [off, setOff] = useState(false);
  const pixels = PixelRatio.getPixelSizeForLayoutSize(Math.max(1, width));
  const ask = pixels <= 800 ? 800 : pixels <= 1600 ? 1600 : 2400;
  const [x = '50%', y = '50%'] = photo.focus.split(/\s+/);
  return (
    <View style={[{ overflow: 'hidden', backgroundColor: photo.tone[photo.tone.length - 1] }, style]}>
      <LinearGradient pointerEvents="none" colors={photo.tone} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
      {off ? null : (
        <Image
          source={{ uri: `https://images.unsplash.com/${photo.id}?auto=format&fit=crop&w=${ask}&q=80` }}
          contentFit="cover"
          contentPosition={{ left: x, top: y }}
          cachePolicy="memory-disk"
          transition={200}
          onError={() => setOff(true)}
          style={StyleSheet.absoluteFill}
          accessibilityIgnoresInvertColors
        />
      )}
    </View>
  );
}
