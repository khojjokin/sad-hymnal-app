import React, { useContext } from 'react';
import * as RN from 'react-native';
import { Platform, StyleSheet, Text as RNText, TextInput as RNTextInput, type TextInputProps, type TextProps, type TextStyle } from 'react-native';

/*
 * The app's two faces (both SIL Open Font Licence, in assets/fonts as static cuts):
 *
 *   Plus Jakarta Sans — everything you tap and scan: lists, buttons, settings, the tab bar.
 *   Newsreader        — an editorial serif with optical sizes, for what you read and sing: hymn
 *                       titles, the banner, the hymn numbers and the words.
 *
 * Every screen imports Text from here. The weight a style asks for picks the sans cut. A style that
 * names a fontFamily (serif(), below) is left alone, and so is a Text inside another Text that asks
 * for no weight of its own: it keeps its parent's.
 */
export const APP_FONT_FILES = {
  'PlusJakartaSans-Regular': require('../../assets/fonts/PlusJakartaSans-Regular.ttf'),
  'PlusJakartaSans-Medium': require('../../assets/fonts/PlusJakartaSans-Medium.ttf'),
  'PlusJakartaSans-SemiBold': require('../../assets/fonts/PlusJakartaSans-SemiBold.ttf'),
  'PlusJakartaSans-Bold': require('../../assets/fonts/PlusJakartaSans-Bold.ttf'),
  'PlusJakartaSans-ExtraBold': require('../../assets/fonts/PlusJakartaSans-ExtraBold.ttf'),
  'Newsreader-Regular': require('../../assets/fonts/Newsreader-Regular.ttf'),
  'Newsreader-Italic': require('../../assets/fonts/Newsreader-Italic.ttf'),
  'Newsreader-Medium': require('../../assets/fonts/Newsreader-Medium.ttf'),
  'Newsreader-SemiBold': require('../../assets/fonts/Newsreader-SemiBold.ttf'),
  'Newsreader-Bold': require('../../assets/fonts/Newsreader-Bold.ttf'),
};

function weightOf(w: TextStyle['fontWeight']): number {
  if (w === undefined || w === 'normal') return 400;
  if (w === 'bold') return 700;
  const n = typeof w === 'number' ? w : parseInt(String(w), 10);
  return Number.isFinite(n) ? n : 400;
}

/** Whether a Text sits inside another Text. React Native has this; its web version doesn't, so a stand-in. */
const TextAncestor: React.Context<boolean> = (RN as any).unstable_TextAncestorContext ?? React.createContext(false);

/** Android draws a named cut and then fakes the weight on top unless the weight is cleared. */
const clearWeight = Platform.OS === 'android' ? ({ fontWeight: 'normal' } as const) : null;

export function sans(weight: TextStyle['fontWeight']): string {
  const w = weightOf(weight);
  if (w >= 800) return 'PlusJakartaSans-ExtraBold';
  if (w >= 700) return 'PlusJakartaSans-Bold';
  if (w >= 600) return 'PlusJakartaSans-SemiBold';
  if (w >= 500) return 'PlusJakartaSans-Medium';
  return 'PlusJakartaSans-Regular';
}

/** The serif as a style: `weight` 400–700, or 'italic'. Spread into a Text's style. */
export function serif(weight: 400 | 500 | 600 | 700 | 'italic' = 400): TextStyle {
  const family = weight === 'italic' ? 'Newsreader-Italic' : weight >= 700 ? 'Newsreader-Bold' : weight >= 600 ? 'Newsreader-SemiBold' : weight >= 500 ? 'Newsreader-Medium' : 'Newsreader-Regular';
  return { fontFamily: family, fontWeight: 'normal', fontStyle: 'normal' };
}

function faceFor(style: TextProps['style'], nested: boolean): TextStyle | null {
  const flat = (StyleSheet.flatten(style) ?? {}) as TextStyle;
  if (flat.fontFamily) return null;
  if (nested && flat.fontWeight === undefined) return null;
  return { fontFamily: sans(flat.fontWeight), ...(clearWeight ?? {}) };
}

export function Text(props: TextProps) {
  const nested = useContext(TextAncestor);
  const face = faceFor(props.style, nested);
  return <RNText {...props} style={face ? [props.style, face] : props.style} />;
}

export const TextInput = React.forwardRef<RNTextInput, TextInputProps>(function TextInput(props, ref) {
  const face = faceFor(props.style, false);
  return <RNTextInput ref={ref} {...props} style={face ? [props.style, face] : props.style} />;
});
export type TextInput = RNTextInput;
