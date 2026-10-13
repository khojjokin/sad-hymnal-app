import React, { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react';
import { AccessibilityInfo, Animated, Easing, Keyboard, KeyboardAvoidingView, Modal, PanResponder, Platform, Pressable, StyleSheet, useWindowDimensions, View, type ViewStyle } from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { setStatusBarStyle } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { tap } from '../lib/haptics';
import { C } from '../lib/theme';
import { Icon, type IconName } from './Icon';
import { serif, Text, TextInput } from './Text';

/*
 * The SDA app's building blocks, carried over as they are: the press that gives under the finger,
 * buttons, the round header buttons, the search field, the switch, settings rows, the bottom sheet and
 * the small message that fades in at the bottom.
 */

/* ---------- reduce motion ---------- */

let reduceMotion = false;
AccessibilityInfo.isReduceMotionEnabled()
  .then((on) => (reduceMotion = on))
  .catch(() => {});
AccessibilityInfo.addEventListener?.('reduceMotionChanged', (on) => (reduceMotion = on));
export const reduceMotionNow = () => reduceMotion;

/* ---------- one tap at a time ---------- */

/** A second tap within a third of a second is the same tap (a double tap opens one screen, not two). */
export function useOneTap(fn: (() => void) | undefined): (() => void) | undefined {
  const last = useRef(0);
  const ref = useRef(fn);
  ref.current = fn;
  const handler = useCallback(() => {
    const now = Date.now();
    if (now - last.current < 320) return;
    last.current = now;
    ref.current?.();
  }, []);
  return fn ? handler : undefined;
}

/** The press every button shares: a slight shrink and fade (only the fade with Reduce Motion on). */
export function pressFx(pressed: boolean, scale = 0.96): ViewStyle {
  if (!pressed) return {};
  return reduceMotion ? { opacity: 0.6 } : { opacity: 0.8, transform: [{ scale }] };
}

/* ---------- buttons ---------- */

export function Button({ label, onPress, kind = 'primary', small, disabled, style, icon }: { label: string; onPress?: () => void; kind?: 'primary' | 'ghost' | 'danger'; small?: boolean; disabled?: boolean; style?: ViewStyle; icon?: IconName }) {
  const bg = kind === 'primary' ? C.accent : kind === 'danger' ? C.like : C.surface2;
  const fg = kind === 'ghost' ? C.fg : '#ffffff';
  const press = useOneTap(onPress ? () => { tap('light'); onPress(); } : undefined);
  return (
    <Pressable
      onPress={disabled ? undefined : press}
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: !!disabled }}
      style={({ pressed }) => [{ height: small ? 34 : 48, paddingHorizontal: small ? 16 : 20, borderRadius: small ? 10 : 12, backgroundColor: bg, flexDirection: 'row', gap: 8, alignItems: 'center', justifyContent: 'center', opacity: disabled ? 0.45 : 1 }, pressFx(pressed && !disabled, small ? 0.96 : 0.98), style]}>
      {icon ? <Icon name={icon} size={small ? 17 : 20} color={fg} weight={2.1} /> : null}
      <Text numberOfLines={1} style={{ color: fg, fontWeight: '600', fontSize: small ? 14 : 16 }}>{label}</Text>
    </Pressable>
  );
}

export function IconButton({ name, onPress, size = 24, color = C.fg, label, fill }: { name: IconName; onPress?: () => void; size?: number; color?: string; label: string; fill?: boolean }) {
  const press = useOneTap(onPress ? () => { tap('light'); onPress(); } : undefined);
  return (
    <Pressable onPress={press} hitSlop={8} accessibilityRole="button" accessibilityLabel={label} style={({ pressed }) => ({ width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center', ...pressFx(pressed, 0.88) })}>
      <Icon name={name} size={size} color={color} fill={fill} />
    </Pressable>
  );
}

/** The round button used in screen headers. */
export function RoundButton({ name, onPress, label, size = 44, bg = C.round, color = C.fg, iconSize = 24 }: { name: IconName; onPress?: () => void; label: string; size?: number; bg?: string; color?: string; iconSize?: number }) {
  const press = useOneTap(onPress ? () => { tap('light'); onPress(); } : undefined);
  return (
    <Pressable onPress={press} hitSlop={6} accessibilityRole="button" accessibilityLabel={label} style={({ pressed }) => ({ width: size, height: size, borderRadius: size / 2, alignItems: 'center', justifyContent: 'center', backgroundColor: bg, borderWidth: StyleSheet.hairlineWidth, borderColor: C.hairline, ...pressFx(pressed, 0.92) })}>
      <Icon name={name} size={iconSize} color={color} />
    </Pressable>
  );
}

export function SearchField({ value, onChangeText, placeholder = 'Search', label, autoFocus, style }: { value: string; onChangeText: (t: string) => void; placeholder?: string; label?: string; autoFocus?: boolean; style?: ViewStyle }) {
  return (
    <View style={[{ flexDirection: 'row', alignItems: 'center', gap: 8, marginHorizontal: 16, paddingHorizontal: 12, height: 40, borderRadius: 12, backgroundColor: C.field }, style]}>
      <Icon name="search" size={17} color={C.fg2} weight={2.2} />
      <TextInput value={value} onChangeText={onChangeText} placeholder={placeholder} placeholderTextColor={C.fg2} autoFocus={autoFocus} style={{ flex: 1, color: C.fg, fontSize: 16.5, paddingVertical: 0 }} autoCapitalize="none" autoCorrect={false} returnKeyType="search" clearButtonMode="while-editing" keyboardAppearance={C.blurTint} accessibilityLabel={label ?? placeholder} />
      {value && Platform.OS !== 'ios' ? (
        <Pressable onPress={() => onChangeText('')} hitSlop={10} accessibilityRole="button" accessibilityLabel="Clear">
          <Icon name="close" size={16} color={C.fg2} weight={2.2} />
        </Pressable>
      ) : null}
    </View>
  );
}

/** On or off: the SDA app's switch. */
export function Toggle({ value, onChange, label }: { value: boolean; onChange: (next: boolean) => void; label: string }) {
  const pos = useRef(new Animated.Value(value ? 1 : 0)).current;
  useEffect(() => {
    Animated.timing(pos, { toValue: value ? 1 : 0, duration: 140, useNativeDriver: true }).start();
  }, [value, pos]);
  return (
    <Pressable onPress={() => { tap('select'); onChange(!value); }} hitSlop={8} accessibilityRole="switch" accessibilityLabel={label} accessibilityState={{ checked: value }} style={{ width: 52, height: 30, borderRadius: 15, backgroundColor: value ? C.accent : C.surface2, justifyContent: 'center' }}>
      <Animated.View style={{ width: 26, height: 26, borderRadius: 13, marginLeft: 2, backgroundColor: '#ffffff', shadowColor: '#000', shadowOpacity: 0.18, shadowRadius: 2, shadowOffset: { width: 0, height: 1 }, transform: [{ translateX: pos.interpolate({ inputRange: [0, 1], outputRange: [0, 22] }) }] }} />
    </Pressable>
  );
}

export function Radio({ on }: { on: boolean }) {
  return (
    <View style={{ width: 24, height: 24, borderRadius: 12, borderWidth: on ? 2 : 1.5, borderColor: on ? C.fg : C.fg3, alignItems: 'center', justifyContent: 'center' }}>
      {on ? <View style={{ width: 13, height: 13, borderRadius: 7, backgroundColor: C.fg }} /> : null}
    </View>
  );
}

/* ---------- page furniture ---------- */

/** The status bar's colour while this screen is in front: 'light' over photos, else the theme's. */
export function useBarStyle(style?: 'light' | 'dark') {
  const want = style ?? C.statusBar;
  useFocusEffect(
    useCallback(() => {
      setStatusBarStyle(want, true);
    }, [want]),
  );
}


export function Screen({ children, edges = true, style }: { children: React.ReactNode; edges?: boolean; style?: ViewStyle }) {
  const insets = useSafeAreaInsets();
  useBarStyle(edges ? undefined : 'light');
  return <View style={[{ flex: 1, backgroundColor: C.bg, paddingTop: edges ? insets.top : 0 }, style]}>{children}</View>;
}

/** A round back button, the title in the middle, room for one button on the right. */
export function ScreenHeader({ title, right, noBack }: { title: string; right?: React.ReactNode; noBack?: boolean }) {
  const router = useRouter();
  return (
    <View style={{ height: 56, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16 }}>
      <View style={{ minWidth: 64, flexShrink: 0 }}>{noBack ? null : <RoundButton name="back" label="Back" onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))} />}</View>
      <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.78} accessibilityRole="header" style={{ flex: 1, color: C.fg, fontSize: 20, fontWeight: '700', letterSpacing: -0.2, textAlign: 'center', paddingHorizontal: 8 }}>
        {title}
      </Text>
      <View style={{ minWidth: 64, flexShrink: 0, alignItems: 'flex-end' }}>{right}</View>
    </View>
  );
}

/** A tab's own header: its name large on the left (as Instagram's), buttons on the right. */
export function TabHeader({ title, right }: { title: string; right?: React.ReactNode }) {
  return (
    <View style={{ height: 56, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, gap: 8 }}>
      <Text accessibilityRole="header" numberOfLines={1} style={{ flex: 1, color: C.fg, fontSize: 26, fontWeight: '800', letterSpacing: -0.5 }}>
        {title}
      </Text>
      {right}
    </View>
  );
}

export function SectionLabel({ children, right }: { children: string; right?: React.ReactNode }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingTop: 24, paddingBottom: 8 }}>
      <Text accessibilityRole="header" style={{ color: C.fg2, fontSize: 15, fontWeight: '600', letterSpacing: 0.1 }}>
        {children}
      </Text>
      {right}
    </View>
  );
}

export function Empty({ title, body, icon, action }: { title: string; body?: string; icon: IconName; action?: React.ReactNode }) {
  return (
    <View style={{ alignItems: 'center', paddingHorizontal: 36, paddingTop: 56, gap: 12 }}>
      <View style={{ width: 86, height: 86, borderRadius: 43, borderWidth: 2, borderColor: C.fg, alignItems: 'center', justifyContent: 'center', marginBottom: 6 }}>
        <Icon name={icon} size={40} color={C.fg} weight={1.6} />
      </View>
      <Text style={[serif(600), { color: C.fg, fontSize: 26, lineHeight: 31, textAlign: 'center' }]}>{title}</Text>
      {body ? <Text style={{ color: C.fg2, fontSize: 15, lineHeight: 21, textAlign: 'center' }}>{body}</Text> : null}
      {action}
    </View>
  );
}

/* ---------- bottom sheet ---------- */

export function Sheet({ visible, onClose, onClosed, title, children }: { visible: boolean; onClose: () => void; /** Once it has fully gone (safe to open the system share sheet). */ onClosed?: () => void; title?: string; children: React.ReactNode }) {
  const insets = useSafeAreaInsets();
  const { height: screenH } = useWindowDimensions();
  const slide = useRef(new Animated.Value(1)).current;
  const drag = useRef(new Animated.Value(0)).current;
  const closeRef = useRef(onClose);
  closeRef.current = onClose;
  const closedRef = useRef(onClosed);
  closedRef.current = onClosed;
  // What it showed while open stays while it slides away.
  const kept = useRef({ title, children });
  if (visible) kept.current = { title, children };
  const shown = visible ? { title, children } : kept.current;
  const [mounted, setMounted] = useState(visible);

  useEffect(() => {
    if (visible) {
      setMounted(true);
      drag.setValue(0);
      if (reduceMotion) return slide.setValue(0);
      Animated.timing(slide, { toValue: 0, duration: 300, easing: Easing.out(Easing.cubic), useNativeDriver: true }).start();
    } else {
      Animated.timing(slide, { toValue: 1, duration: 220, easing: Easing.in(Easing.cubic), useNativeDriver: true }).start(({ finished }) => {
        if (!finished) return;
        setMounted(false);
        // On iPhone the modal is only gone once it has dismissed (onDismiss below).
        if (Platform.OS !== 'ios') closedRef.current?.();
      });
    }
  }, [visible, slide, drag]);

  const pan = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, g) => g.dy > 6 && Math.abs(g.dy) > Math.abs(g.dx),
      onPanResponderMove: (_, g) => drag.setValue(Math.max(0, g.dy)),
      onPanResponderRelease: (_, g) => {
        if (g.dy > 110 || (g.vy > 0.8 && g.dy > 24)) closeRef.current();
        else Animated.spring(drag, { toValue: 0, useNativeDriver: true, bounciness: 4, speed: 18 }).start();
      },
    }),
  ).current;

  const translateY = useMemo(() => Animated.add(slide.interpolate({ inputRange: [0, 1], outputRange: [0, screenH] }), drag), [slide, drag, screenH]);

  return (
    <Modal visible={visible || mounted} transparent animationType="fade" onRequestClose={onClose} onDismiss={Platform.OS === 'ios' ? () => closedRef.current?.() : undefined} statusBarTranslucent navigationBarTranslucent>
      <KeyboardAvoidingView style={{ flex: 1, justifyContent: 'flex-end' }} behavior={Platform.OS === 'ios' ? 'padding' : undefined} pointerEvents={visible ? 'auto' : 'none'}>
        <Pressable style={[StyleSheet.absoluteFill, { backgroundColor: C.scrim }]} onPress={onClose} accessibilityLabel="Close" />
        <Animated.View style={{ backgroundColor: C.sheet, borderTopLeftRadius: 30, borderTopRightRadius: 30, paddingBottom: insets.bottom + 12, maxHeight: '90%', transform: [{ translateY }] }}>
          <View {...pan.panHandlers}>
            <View style={{ alignItems: 'center', paddingTop: 12, paddingBottom: shown.title ? 0 : 10 }}>
              <View style={{ width: 36, height: 4, borderRadius: 2, backgroundColor: C.fg3 }} />
            </View>
            {shown.title ? (
              <Text accessibilityRole="header" numberOfLines={2} style={{ color: C.fg, fontSize: 19, fontWeight: '700', textAlign: 'center', paddingVertical: 18, paddingHorizontal: 24 }}>
                {shown.title}
              </Text>
            ) : null}
          </View>
          {shown.children}
        </Animated.View>
        <ToastOutlet />
      </KeyboardAvoidingView>
    </Modal>
  );
}

export function SheetRow({ icon, label, sub, onPress, danger, first, right }: { icon: IconName; label: string; sub?: string; onPress: () => void; danger?: boolean; first?: boolean; right?: React.ReactNode }) {
  const color = danger ? C.like : C.fg;
  const press = useOneTap(() => { tap('light'); onPress(); });
  return (
    <Pressable onPress={press} accessibilityRole="button" accessibilityLabel={label} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 14, paddingLeft: 18, minHeight: 54, backgroundColor: pressed ? C.press : 'transparent' })}>
      <Icon name={icon} size={25} color={color} />
      <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 10, minHeight: 54, paddingRight: 18, borderTopWidth: first ? 0 : StyleSheet.hairlineWidth, borderTopColor: C.line }}>
        <View style={{ flex: 1, paddingVertical: sub ? 8 : 0 }}>
          <Text style={{ color, fontSize: 17, fontWeight: '500' }}>{label}</Text>
          {sub ? <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 1 }}>{sub}</Text> : null}
        </View>
        {right}
      </View>
    </Pressable>
  );
}

/* ---------- the message at the bottom ---------- */

let toastNow = { id: 0, msg: '' };
const toastListeners = new Set<() => void>();
export function toast(msg: string) {
  toastNow = { id: toastNow.id + 1, msg };
  toastListeners.forEach((l) => l());
}
const subscribeToast = (l: () => void) => {
  toastListeners.add(l);
  return () => {
    toastListeners.delete(l);
  };
};

export function ToastOutlet() {
  const now = useSyncExternalStore(subscribeToast, () => toastNow);
  const insets = useSafeAreaInsets();
  const fade = useRef(new Animated.Value(0)).current;
  const [msg, setMsg] = useState('');
  const seen = useRef(now.id);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [keyboard, setKeyboard] = useState(0);
  useEffect(() => {
    const ios = Platform.OS === 'ios';
    const up = Keyboard.addListener(ios ? 'keyboardWillShow' : 'keyboardDidShow', (e) => setKeyboard(e.endCoordinates.height));
    const down = Keyboard.addListener(ios ? 'keyboardWillHide' : 'keyboardDidHide', () => setKeyboard(0));
    return () => {
      up.remove();
      down.remove();
    };
  }, []);
  useEffect(() => {
    if (now.id === seen.current) return;
    seen.current = now.id;
    setMsg(now.msg);
    if (timer.current) clearTimeout(timer.current);
    Animated.timing(fade, { toValue: 1, duration: 160, useNativeDriver: true }).start();
    timer.current = setTimeout(() => {
      Animated.timing(fade, { toValue: 0, duration: 200, useNativeDriver: true }).start(({ finished }) => finished && setMsg(''));
    }, 2000);
  }, [now, fade]);
  if (!msg) return null;
  return (
    <Animated.View pointerEvents="none" accessibilityLiveRegion="polite" style={{ position: 'absolute', left: 24, right: 24, bottom: keyboard ? keyboard + 16 : insets.bottom + 100, alignItems: 'center', opacity: fade }}>
      <View style={{ backgroundColor: C.fg, paddingHorizontal: 18, paddingVertical: 11, borderRadius: 14 }}>
        <Text style={{ color: C.bg, fontWeight: '600', textAlign: 'center' }}>{msg}</Text>
      </View>
    </Animated.View>
  );
}
