import React, { useMemo, useRef, useState } from 'react';
import { Animated, Pressable, ScrollView, Share, StyleSheet, useWindowDimensions, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import { useOpenHymn } from '../../src/components/HymnLine';
import { Icon, type IconName } from '../../src/components/Icon';
import { Photo } from '../../src/components/Photo';
import { HeroButton, PhotoHero, useHeroLayout, useHeroScroll } from '../../src/components/PhotoHero';
import { useTabBarSpace } from '../../src/components/TabBar';
import { serif, Text } from '../../src/components/Text';
import { pressFx, Screen, SectionLabel, toast } from '../../src/components/ui';
import { tap } from '../../src/lib/haptics';
import { dayNumber, hymnByNumber, HYMNS, hymnsForMoment, momentNow, PARTS, pick, plainWords, sectionsOfPart, versesOf, type Hymn } from '../../src/lib/hymnal';
import { type Key, useT } from '../../src/lib/i18n';
import { toggleFavourite, usePrefs } from '../../src/lib/prefs';
import { STORIES, WRITERS } from '../../src/lib/stories';
import { C, SEA } from '../../src/lib/theme';

/*
 * Discover, laid out like the SDA app's Sabbath School page: a photo banner with a greeting, then
 * cards. Each day brings a new hymn of the day, a story behind a hymn, a writer to meet and hymns for
 * the time of day; the button at the top right shows another set.
 */

const WITH_WORDS = HYMNS.filter((h) => h.lyrics && h.number < 660);

function greeting(): Key {
  const now = new Date();
  const d = now.getDay();
  const h = now.getHours();
  if ((d === 5 && h >= 18) || (d === 6 && h < 18)) return 'discover.sabbath';
  return h < 12 ? 'discover.morning' : h < 17 ? 'discover.afternoon' : 'discover.evening';
}

/** A round see-through button on the blue card. */
function CardButton({ icon, label, onPress, on }: { icon: IconName; label: string; onPress: () => void; on?: boolean }) {
  return (
    <Pressable onPress={onPress} accessibilityRole="button" accessibilityLabel={label} hitSlop={4} style={({ pressed }) => [{ width: 50, height: 50, borderRadius: 25, backgroundColor: 'rgba(255,255,255,0.16)', alignItems: 'center', justifyContent: 'center' }, pressFx(pressed, 0.9)]}>
      <Icon name={icon} size={23} color="#ffffff" fill={on} weight={2} />
    </Pressable>
  );
}

function Card({ children, style }: { children: React.ReactNode; style?: object }) {
  return <View style={[{ marginHorizontal: 16, borderRadius: 26, backgroundColor: C.surface, overflow: 'hidden' }, style]}>{children}</View>;
}

/** A small line for a hymn inside a card. */
function MiniHymn({ hymn, onOpen, last }: { hymn: Hymn; onOpen: (n: number) => void; last?: boolean }) {
  return (
    <Pressable onPress={() => onOpen(hymn.number)} accessibilityRole="button" accessibilityLabel={`${hymn.number}, ${hymn.title}`} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 12, minHeight: 50, borderBottomWidth: last ? 0 : StyleSheet.hairlineWidth, borderBottomColor: C.line, opacity: pressed ? 0.6 : 1 })}>
      <Text style={[serif(500), { width: 36, color: C.accent2, fontSize: 19, fontVariant: ['lining-nums', 'tabular-nums'] }]}>{hymn.number}</Text>
      <Text numberOfLines={1} style={{ flex: 1, color: C.fg, fontSize: 16, fontWeight: '500' }}>{hymn.title}</Text>
      <Icon name="right" size={17} color={C.fg3} weight={2} />
    </Pressable>
  );
}

export default function Discover() {
  const t = useT();
  const router = useRouter();
  const open = useOpenHymn();
  const prefs = usePrefs();
  const { width } = useWindowDimensions();
  const { scroll, onScroll } = useHeroScroll();
  const { paddingTop } = useHeroLayout(0);
  const bottom = useTabBarSpace();
  const [shuffle, setShuffle] = useState(0);
  const list = useRef<ScrollView>(null);
  const day = dayNumber();

  const today = useMemo(() => pick(WITH_WORDS, day, shuffle, 37), [day, shuffle]);
  const verse = useMemo(() => versesOf(today.lyrics).find((v) => v.kind === 'verse')?.text ?? '', [today]);
  const story = useMemo(() => pick(STORIES, day, shuffle, 5), [day, shuffle]);
  const storyHymn = hymnByNumber(story.hymn)!;
  const writer = useMemo(() => pick(WRITERS, day, shuffle, 3), [day, shuffle]);
  const writerHymns = useMemo(() => HYMNS.filter((h) => h.author.includes(writer.match)), [writer]);
  const moment = momentNow();
  const momentHymns = useMemo(() => {
    const list = hymnsForMoment(moment);
    const start = Math.abs(day * 3 + shuffle * 4) % list.length;
    return [...list.slice(start), ...list.slice(0, start)].slice(0, 4);
  }, [moment, day, shuffle]);
  const momentTitle: Key = moment === 'morning' ? 'discover.forMorning' : moment === 'evening' ? 'discover.forEvening' : moment === 'sabbath' ? 'discover.forSabbath' : 'discover.forPraise';
  const momentIcon: IconName = moment === 'evening' ? 'moon' : moment === 'sabbath' ? 'church' : 'sun';
  const starred = prefs.favourites.includes(today.number);

  const again = () => {
    tap('select');
    setShuffle((s) => s + 1);
    list.current?.scrollTo({ y: 0, animated: true });
  };
  const shareToday = () => {
    Share.share({ message: `Hymn ${today.number} · ${today.title}\n\n${plainWords(today)}${today.author ? `\n\n— ${today.author}` : ''}\n\nSDA Hymnal` }).catch(() => {});
  };
  const heart = () => {
    toggleFavourite(today.number);
    toast(starred ? t('hymn.unliked') : t('hymn.liked'));
  };

  return (
    <Screen edges={false}>
      <Animated.ScrollView ref={list as any} onScroll={onScroll} scrollEventThrottle={16} contentContainerStyle={{ paddingTop: paddingTop + 16, paddingBottom: bottom, gap: 16 }}>
        {/* Hymn of the day: the first verse in large type on the app's blue, as Sabbath School shows the memory text. */}
        <View style={{ marginHorizontal: 16, borderRadius: 26, overflow: 'hidden' }}>
          <LinearGradient colors={SEA as unknown as readonly [string, string, ...string[]]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={{ padding: 22 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
              <Icon name="sun" size={20} color="#ffffff" weight={2} />
              <Text style={{ flex: 1, color: '#ffffff', fontSize: 16, fontWeight: '700' }}>{t('discover.today')}</Text>
              <Text style={[serif(600), { color: 'rgba(255,255,255,0.9)', fontSize: 26, lineHeight: 30, fontVariant: ['lining-nums'] }]}>{today.number}</Text>
            </View>
            <Text style={[serif(600), { color: '#ffffff', fontSize: 27, lineHeight: 32, marginTop: 16 }]}>{today.title}</Text>
            <Text numberOfLines={8} style={[serif(400), { color: 'rgba(255,255,255,0.95)', fontSize: 21, lineHeight: 31, marginTop: 12 }]}>{verse}</Text>
            {today.author ? <Text style={{ color: 'rgba(255,255,255,0.85)', fontSize: 15.5, fontWeight: '700', marginTop: 14 }}>{today.author}</Text> : null}
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 20 }}>
              <CardButton icon="heart" label={starred ? t('hymn.unlike') : t('hymn.like')} onPress={heart} on={starred} />
              <CardButton icon="share" label={t('hymn.share')} onPress={shareToday} />
              <View style={{ flex: 1 }} />
              <Pressable onPress={() => open(today.number)} accessibilityRole="button" style={({ pressed }) => [{ height: 50, paddingHorizontal: 24, borderRadius: 25, backgroundColor: '#ffffff', flexDirection: 'row', alignItems: 'center', gap: 10 }, pressFx(pressed, 0.96)]}>
                <Icon name="hymnal" size={21} color={SEA[0]} weight={2.1} />
                <Text style={{ color: SEA[0], fontSize: 17, fontWeight: '700' }}>{t('discover.sing')}</Text>
              </Pressable>
            </View>
          </LinearGradient>
        </View>

        {/* The story behind a hymn. */}
        <Card>
          <Photo photo={story.photo} width={width - 32} style={{ height: 170 }}>
            <LinearGradient colors={['rgba(0,0,0,0)', 'rgba(0,0,0,0.65)']} style={StyleSheet.absoluteFill} />
            <View style={{ position: 'absolute', left: 20, right: 20, bottom: 16 }}>
              <Text style={{ color: 'rgba(255,255,255,0.88)', fontSize: 14, fontWeight: '600' }}>{t('discover.story')}</Text>
              <Text numberOfLines={2} style={[serif(600), { color: '#ffffff', fontSize: 25, lineHeight: 29, marginTop: 2 }]}>{storyHymn.title}</Text>
            </View>
          </Photo>
          <View style={{ padding: 20, gap: 14 }}>
            <Text style={[serif(400), { color: C.fg, fontSize: 18, lineHeight: 28 }]}>{story.text}</Text>
            <Pressable onPress={() => open(story.hymn)} accessibilityRole="button" style={({ pressed }) => [{ alignSelf: 'flex-start', height: 44, paddingHorizontal: 18, borderRadius: 22, backgroundColor: C.accent, flexDirection: 'row', alignItems: 'center', gap: 8 }, pressFx(pressed, 0.96)]}>
              <Icon name="hymnal" size={19} color="#ffffff" weight={2.1} />
              <Text style={{ color: '#ffffff', fontSize: 15.5, fontWeight: '700' }}>{t('discover.readHymn', { n: story.hymn })}</Text>
            </Pressable>
          </View>
        </Card>

        {/* Hymns for the time of day, or for the Sabbath. */}
        <Card style={{ padding: 20, paddingBottom: 8 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 6 }}>
            <View style={{ width: 42, height: 42, borderRadius: 14, backgroundColor: C.accentSoft, alignItems: 'center', justifyContent: 'center' }}>
              <Icon name={momentIcon} size={22} color={C.accent2} weight={2} />
            </View>
            <Text style={[serif(600), { color: C.fg, fontSize: 23 }]}>{t(momentTitle)}</Text>
          </View>
          {momentHymns.map((h, i) => (
            <MiniHymn key={h.number} hymn={h} onOpen={open} last={i === momentHymns.length - 1} />
          ))}
        </Card>

        {/* A writer and their hymns in the book. */}
        <Card>
          <View style={{ flexDirection: 'row', gap: 16, padding: 20, paddingBottom: 12 }}>
            <Photo photo={writer.photo} width={76} style={{ width: 76, height: 76, borderRadius: 20 }} />
            <View style={{ flex: 1, justifyContent: 'center' }}>
              <Text style={{ color: C.fg2, fontSize: 14, fontWeight: '600' }}>{t('discover.writer')}</Text>
              <Text style={[serif(600), { color: C.fg, fontSize: 24, lineHeight: 28 }]}>{writer.name}</Text>
              <Text style={{ color: C.fg2, fontSize: 14, marginTop: 2 }}>
                {writer.years}, {t('discover.writerCount', { n: writerHymns.length })}
              </Text>
            </View>
          </View>
          <Text style={[serif(400), { color: C.fg, fontSize: 17.5, lineHeight: 27, paddingHorizontal: 20 }]}>{writer.text}</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 10, padding: 20 }}>
            {writerHymns.slice(0, 8).map((h) => (
              <Pressable key={h.number} onPress={() => open(h.number)} accessibilityRole="button" accessibilityLabel={`${h.number}, ${h.title}`} style={({ pressed }) => [{ width: 150, padding: 14, borderRadius: 16, backgroundColor: C.bg, gap: 6 }, pressFx(pressed, 0.96)]}>
                <Text style={[serif(600), { color: C.accent2, fontSize: 24, lineHeight: 28, fontVariant: ['lining-nums'] }]}>{h.number}</Text>
                <Text numberOfLines={2} style={{ color: C.fg, fontSize: 14, fontWeight: '600', lineHeight: 18 }}>{h.title}</Text>
              </Pressable>
            ))}
          </ScrollView>
        </Card>

        {/* The book's parts. */}
        <View>
          <SectionLabel>{t('discover.browse')}</SectionLabel>
          {PARTS.map((p, i) => {
            const topics = sectionsOfPart(p.from, p.to).length;
            return (
              <Pressable key={p.name} onPress={() => router.push({ pathname: '/part/[index]', params: { index: String(i) } })} accessibilityRole="button" accessibilityLabel={`${p.name}, ${t('discover.range', { a: p.from, b: p.to })}`} style={({ pressed }) => ({ flexDirection: 'row', alignItems: 'center', gap: 14, paddingHorizontal: 16, minHeight: 64, backgroundColor: pressed ? C.press : 'transparent' })}>
                <View style={{ width: 42, height: 42, borderRadius: 14, backgroundColor: C.accentSoft, alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name={p.icon} size={21} color={C.accent2} weight={2} />
                </View>
                <View style={{ flex: 1, paddingVertical: 10, borderBottomWidth: i === PARTS.length - 1 ? 0 : StyleSheet.hairlineWidth, borderBottomColor: C.line }}>
                  <Text numberOfLines={1} style={[serif(600), { color: C.fg, fontSize: 19.5, lineHeight: 24 }]}>{p.name}</Text>
                  <Text style={{ color: C.fg2, fontSize: 13.5, marginTop: 1 }}>
                    {t('discover.range', { a: p.from, b: p.to })}
                    {topics > 1 ? `, ${t('discover.topics', { n: topics })}` : ''}
                  </Text>
                </View>
                <Icon name="right" size={18} color={C.fg3} weight={2} />
              </Pressable>
            );
          })}
        </View>
      </Animated.ScrollView>
      <PhotoHero photo="emptyExplore" title={t('discover.title')} line={t(greeting())} scroll={scroll} right={<HeroButton name="shuffle" label={t('discover.shuffle')} onPress={again} />} />
    </Screen>
  );
}
