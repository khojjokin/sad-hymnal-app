import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Platform, Pressable, ScrollView, Share, View } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import { activateKeepAwakeAsync, deactivateKeepAwake } from 'expo-keep-awake';
import { useLocalSearchParams } from 'expo-router';
import * as Sharing from 'expo-sharing';
import * as WebBrowser from 'expo-web-browser';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { captureRef } from 'react-native-view-shot';
import { Backdrop } from '../../src/components/Backdrop';
import { ColourSheet } from '../../src/components/ColourSheet';
import { Icon } from '../../src/components/Icon';
import { NumberSheet } from '../../src/components/NumberSheet';
import { CARD_H, CARD_W, ShareCard } from '../../src/components/ShareCard';
import { serif, Text } from '../../src/components/Text';
import { IconButton, RoundButton, Sheet, SheetRow, toast, useBarStyle } from '../../src/components/ui';
import { useRouter } from 'expo-router';
import { tap } from '../../src/lib/haptics';
import { clampHymn, HYMN_COUNT, hymnaryUrl, hymnByNumber, plainWords, versesOf } from '../../src/lib/hymnal';
import { noteOpened, setPrefs, TEXT_MAX, TEXT_MIN, toggleFavourite, usePrefs } from '../../src/lib/prefs';
import { C } from '../../src/lib/theme';

const SPACING = { compact: 1.38, normal: 1.55, relaxed: 1.75 } as const;

export default function HymnPage() {
  const params = useLocalSearchParams<{ number: string }>();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const prefs = usePrefs();
  useBarStyle();
  const [n, setN] = useState(clampHymn(parseInt(String(params.number ?? '1'), 10)));
  const hymn = hymnByNumber(n)!;
  const [palette, setPalette] = useState(false);
  const [keypad, setKeypad] = useState(false);
  /** The share sheet: closed, or open for the whole hymn (-1) or one verse (its index). */
  const [sharing, setSharing] = useState<number | null>(null);
  const [cardVerse, setCardVerse] = useState('');
  const card = useRef<View>(null);
  /** What to do once the share menu has fully closed: the system's share sheet can't open over it. */
  const afterClose = useRef<(() => void) | null>(null);
  const closeThen = (fn: () => void) => {
    afterClose.current = fn;
    setSharing(null);
  };
  const closed = () => {
    const fn = afterClose.current;
    afterClose.current = null;
    fn?.();
  };
  const scroll = useRef<ScrollView>(null);

  const verses = useMemo(() => (hymn.lyrics ? versesOf(hymn.lyrics, prefs.repeatRefrain) : []), [hymn, prefs.repeatRefrain]);
  const starred = prefs.favourites.includes(n);
  const size = prefs.textSize;
  const lineHeight = Math.round(size * SPACING[prefs.spacing]);
  const words = prefs.font === 'serif';

  useEffect(() => {
    noteOpened(n);
  }, [n]);

  // The screen stays on while a hymn is open, so it doesn't go dark in the middle of a verse.
  useEffect(() => {
    if (!prefs.keepAwake || Platform.OS === 'web') return;
    activateKeepAwakeAsync('hymn').catch(() => {});
    return () => {
      deactivateKeepAwake('hymn').catch(() => {});
    };
  }, [prefs.keepAwake]);

  /** Previous/Next wrap around the ends of the book. */
  const go = (delta: number) => {
    tap('light');
    scroll.current?.scrollTo({ y: 0, animated: false });
    setN(((n - 1 + delta + HYMN_COUNT) % HYMN_COUNT) + 1);
  };
  const jump = (to: number) => {
    scroll.current?.scrollTo({ y: 0, animated: false });
    setN(to);
  };

  const setSize = (next: number) => {
    tap('select');
    setPrefs({ textSize: Math.min(TEXT_MAX, Math.max(TEXT_MIN, next)) });
  };

  const heart = () => {
    toggleFavourite(n);
    toast(starred ? 'Removed from favourites' : 'Added to favourites');
  };

  /* ---------- sharing ---------- */

  const shareVerse = sharing !== null && sharing >= 0 ? verses[sharing] : undefined;
  const firstVerse = verses.find((v) => v.kind === 'verse')?.text ?? '';
  const heading = `Hymn ${hymn.number} · ${hymn.title}`;

  const shareText = async () => {
    const words = shareVerse ? shareVerse.text : plainWords(hymn);
    const body = hymn.lyrics ? `${heading}\n\n${words}${hymn.author ? `\n\n— ${hymn.author}` : ''}\n\nSDA Hymnal` : `${heading}\n${hymnaryUrl(n)}`;
    closeThen(() => {
      Share.share({ message: body, title: hymn.title }).catch(() => {});
    });
  };

  const sharePicture = async () => {
    setCardVerse(shareVerse ? shareVerse.text : firstVerse);
    // Let the card draw with the verse before it is captured.
    await new Promise((r) => setTimeout(r, 120));
    try {
      // Off screen, iOS needs the card drawn into its own context to capture it.
      const uri = await captureRef(card, { format: 'png', quality: 1, width: CARD_W * 3, height: CARD_H * 3, useRenderInContext: Platform.OS === 'ios' });
      const can = await Sharing.isAvailableAsync();
      closeThen(() => {
        if (can) Sharing.shareAsync(uri, { mimeType: 'image/png', dialogTitle: hymn.title, UTI: 'public.png' }).catch(() => {});
        else toast("Sharing isn't available here");
      });
    } catch {
      setSharing(null);
      toast("Couldn't make the picture");
    }
  };

  const copyWords = async () => {
    await Clipboard.setStringAsync(shareVerse ? shareVerse.text : `${heading}\n\n${plainWords(hymn)}`);
    setSharing(null);
    toast('Copied');
  };

  const copyLink = async () => {
    await Clipboard.setStringAsync(hymnaryUrl(n));
    setSharing(null);
    toast('Link copied');
  };

  const lookUp = () => WebBrowser.openBrowserAsync(hymnaryUrl(n)).catch(() => {});

  const step = (dir: -1 | 1) => (
    <Pressable onPress={() => go(dir)} hitSlop={8} accessibilityRole="button" accessibilityLabel={dir < 0 ? 'Previous hymn' : 'Next hymn'} style={({ pressed }) => ({ flexDirection: dir < 0 ? 'row' : 'row-reverse', alignItems: 'center', gap: 6, height: 42, paddingHorizontal: 16, borderRadius: 21, backgroundColor: C.surface, opacity: pressed ? 0.6 : 1 })}>
      <Icon name={dir < 0 ? 'back' : 'right'} size={17} color={C.fg2} weight={2.2} />
      <Text style={{ color: C.fg, fontWeight: '600' }}>{dir < 0 ? `${n === 1 ? HYMN_COUNT : n - 1}` : `${n === HYMN_COUNT ? 1 : n + 1}`}</Text>
    </Pressable>
  );

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Backdrop reading />
      <View style={{ flex: 1, paddingTop: insets.top }}>
        <View style={{ height: 56, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, gap: 2 }}>
          <RoundButton name="back" label="Back" onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))} />
          <View style={{ flex: 1 }} />
          <IconButton name="heart" label={starred ? 'Remove from favourites' : 'Add to favourites'} fill={starred} color={starred ? C.like : C.fg} onPress={heart} />
          <IconButton name="share" label="Share" onPress={() => setSharing(-1)} />
          <IconButton name="palette" label="Hymn background" onPress={() => setPalette(true)} />
        </View>

        <ScrollView ref={scroll} contentContainerStyle={{ paddingBottom: insets.bottom + 30 }}>
          <View style={{ paddingHorizontal: 22, paddingTop: 2, paddingBottom: 22 }}>
            <View style={{ flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between' }}>
              {/* The hymn's number, as large as the hymn board at the front of the church. Tap it to go to another. */}
              <Pressable onPress={() => setKeypad(true)} accessibilityRole="button" accessibilityLabel={`Hymn ${n}. Go to another number`} hitSlop={6} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'flex-end', gap: 4, opacity: pressed ? 0.6 : 1 })}>
                <Text accessibilityRole="header" style={[serif(600), { color: C.accent2, fontSize: 76, lineHeight: 80, letterSpacing: -2, fontVariant: ['lining-nums', 'tabular-nums'] }]}>{n}</Text>
                <View style={{ paddingBottom: 14 }}>
                  <Icon name="down" size={16} color={C.fg3} weight={2.4} />
                </View>
              </Pressable>
              {verses.length ? (
                <View style={{ flexDirection: 'row', gap: 8, paddingBottom: 12 }}>
                  {[
                    { label: 'A−', a11y: 'Smaller text', delta: -2, off: size <= TEXT_MIN },
                    { label: 'A+', a11y: 'Larger text', delta: 2, off: size >= TEXT_MAX },
                  ].map((b) => (
                    <Pressable key={b.label} onPress={() => setSize(size + b.delta)} disabled={b.off} accessibilityRole="button" accessibilityLabel={b.a11y} accessibilityState={{ disabled: b.off }} style={({ pressed }) => ({ height: 34, minWidth: 46, paddingHorizontal: 12, borderRadius: 17, backgroundColor: pressed ? C.surface2 : C.surface, alignItems: 'center', justifyContent: 'center', opacity: b.off ? 0.4 : 1 })}>
                      <Text style={{ color: C.fg, fontSize: 14, fontWeight: '600' }}>{b.label}</Text>
                    </Pressable>
                  ))}
                </View>
              ) : null}
            </View>
            {hymn.section ? <Text style={{ color: C.fg3, fontSize: 13.5, fontWeight: '500', marginTop: 12 }}>{hymn.section}</Text> : null}
            <Text style={[serif(600), { color: C.fg, fontSize: 31, lineHeight: 35, letterSpacing: -0.3, marginTop: 4 }]}>{hymn.title}</Text>
            {hymn.author ? <Text style={[serif('italic'), { color: C.fg2, fontSize: 17, lineHeight: 22, marginTop: 6 }]}>{hymn.author}</Text> : null}
          </View>

          {verses.length ? (
            <>
              <View style={{ paddingHorizontal: 22, gap: Math.round(size * 1.1) }}>
                {verses.map((v, i) => {
                  const refrain = v.kind === 'refrain';
                  return (
                    // A long press shares just this verse.
                    <Pressable key={i} onLongPress={() => { tap('select'); setSharing(i); }} delayLongPress={350} accessibilityHint="Long press to share this verse" style={refrain ? { paddingLeft: 14, borderLeftWidth: 2, borderLeftColor: C.accent2 } : null}>
                      {refrain ? <Text style={{ color: C.accent2, fontSize: 13, fontWeight: '600', marginBottom: 2 }}>Refrain</Text> : null}
                      <Text style={[{ color: C.fg, fontSize: size, lineHeight }, words ? serif(refrain ? 'italic' : 400) : { fontStyle: refrain ? 'italic' : 'normal' }]}>
                        {!refrain && prefs.verseNumbers ? <Text style={{ color: C.accent2, fontSize: Math.round(size * 0.66), fontWeight: '700', fontStyle: 'normal' }}>{v.number}{'  '}</Text> : null}
                        {v.text}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
            </>
          ) : (
            <View style={{ paddingHorizontal: 22, gap: 6 }}>
              <Text style={[serif(400), { color: C.fg2, fontSize: 18, lineHeight: 27 }]}>The words of this hymn are still under copyright, so they aren't in the app. You'll find them in the printed hymnal at number {n}.</Text>
              <Pressable onPress={lookUp} accessibilityRole="link" accessibilityLabel="See this hymn on Hymnary.org" style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 10, alignSelf: 'flex-start', paddingVertical: 10, opacity: pressed ? 0.6 : 1 })}>
                <Icon name="globe" size={20} color={C.accent2} weight={2} />
                <Text style={{ color: C.accent2, fontSize: 15.5, fontWeight: '700' }}>See it on Hymnary.org</Text>
              </Pressable>
            </View>
          )}

          <View style={{ flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 22, paddingTop: 30 }}>
            {step(-1)}
            {step(1)}
          </View>
        </ScrollView>
      </View>

      {/* The picture for sharing, drawn off screen until it's captured. */}
      {hymn.lyrics ? (
        <View pointerEvents="none" style={{ position: 'absolute', left: -CARD_W * 3, top: 0 }}>
          <ShareCard ref={card} hymn={hymn} verse={cardVerse || firstVerse} />
        </View>
      ) : null}

      <Sheet visible={sharing !== null} onClose={() => setSharing(null)} onClosed={closed} title={shareVerse ? (shareVerse.kind === 'refrain' ? 'Share the refrain' : `Share verse ${shareVerse.number}`) : `Share hymn ${n}`}>
        <View style={{ paddingBottom: 6 }}>
          {hymn.lyrics ? (
            <>
              <SheetRow first icon="image" label="Share as a picture" sub={shareVerse ? undefined : 'With the first verse'} onPress={sharePicture} />
              <SheetRow icon="share" label={shareVerse ? 'Share the words' : 'Share the hymn'} onPress={shareText} />
              <SheetRow icon="copy" label="Copy the words" onPress={copyWords} />
            </>
          ) : (
            <SheetRow first icon="share" label="Share the hymn" sub="Its number, title and a link" onPress={shareText} />
          )}
          <SheetRow icon="link" label="Copy link to Hymnary.org" onPress={copyLink} />
        </View>
      </Sheet>
      <ColourSheet visible={palette} onClose={() => setPalette(false)} />
      <NumberSheet visible={keypad} onClose={() => setKeypad(false)} onOpen={jump} />
    </View>
  );
}
