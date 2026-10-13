import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';
import { getPrefs } from './prefs';

/** A small tap under the finger, unless haptics are off in Settings. */
export function tap(kind: 'light' | 'select' | 'success' = 'light') {
  if (Platform.OS === 'web' || !getPrefs().haptics) return;
  if (kind === 'select') Haptics.selectionAsync().catch(() => {});
  else if (kind === 'success') Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
  else Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
}
