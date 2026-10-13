import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

/** A small tap under the finger. */
export function tap(kind: 'light' | 'select' | 'success' = 'light') {
  if (Platform.OS === 'web') return;
  if (kind === 'select') Haptics.selectionAsync().catch(() => {});
  else if (kind === 'success') Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
  else Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
}
