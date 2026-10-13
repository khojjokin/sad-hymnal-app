import React, { useContext } from 'react';
import { Platform, StyleSheet, Text as RNText, TextInput as RNTextInput, type TextInputProps, type TextProps, type TextStyle, unstable_TextAncestorContext } from 'react-native';

/*
 * The app's Text and TextInput, set in Outfit (assets/fonts, SIL Open Font Licence), the SDA app's
 * face. The weight a style asks for picks the cut. A style that names its own fontFamily (the serif
 * reading face) is left alone, and so is a Text inside another Text that asks for no weight: it keeps
 * its parent's.
 */
export const APP_FONT_FILES = {
  'Outfit-Regular': require('../../assets/fonts/Outfit-Regular.ttf'),
  'Outfit-Medium': require('../../assets/fonts/Outfit-Medium.ttf'),
  'Outfit-SemiBold': require('../../assets/fonts/Outfit-SemiBold.ttf'),
  'Outfit-Bold': require('../../assets/fonts/Outfit-Bold.ttf'),
  'Outfit-ExtraBold': require('../../assets/fonts/Outfit-ExtraBold.ttf'),
};

/** The reading serif: the phone's own (Georgia on iPhone, Noto Serif on Android). */
export const SERIF = Platform.select({ ios: 'Georgia', android: 'serif', default: 'Georgia, serif' }) as string;

function weightOf(w: TextStyle['fontWeight']): number {
  if (w === undefined || w === 'normal') return 400;
  if (w === 'bold') return 700;
  const n = typeof w === 'number' ? w : parseInt(String(w), 10);
  return Number.isFinite(n) ? n : 400;
}

export function outfit(weight: TextStyle['fontWeight']): string {
  const w = weightOf(weight);
  if (w >= 800) return 'Outfit-ExtraBold';
  if (w >= 700) return 'Outfit-Bold';
  if (w >= 600) return 'Outfit-SemiBold';
  if (w >= 500) return 'Outfit-Medium';
  return 'Outfit-Regular';
}

function faceFor(style: TextProps['style'], nested: boolean): TextStyle | null {
  const flat = (StyleSheet.flatten(style) ?? {}) as TextStyle;
  if (flat.fontFamily) return null;
  if (nested && flat.fontWeight === undefined) return null;
  // Android draws a named cut and then fakes the weight on top unless the weight is cleared.
  return { fontFamily: outfit(flat.fontWeight), fontWeight: Platform.OS === 'android' ? 'normal' : flat.fontWeight };
}

export function Text(props: TextProps) {
  const nested = useContext(unstable_TextAncestorContext);
  const face = faceFor(props.style, nested);
  return <RNText {...props} style={face ? [props.style, face] : props.style} />;
}

export const TextInput = React.forwardRef<RNTextInput, TextInputProps>(function TextInput(props, ref) {
  const face = faceFor(props.style, false);
  return <RNTextInput ref={ref} {...props} style={face ? [props.style, face] : props.style} />;
});
export type TextInput = RNTextInput;
