# SDA Hymnal

All 695 hymns of the Seventh-day Adventist Hymnal (1985), numbered as in the printed book, for iPhone and Android. Works fully offline. By Mojo.

## What's in it

- **Hymnal** — the same page as the SDA app's Hymnal: photo banner, search by number, title, author or first line, favourites at the top, then every section in book order. The **#** button opens a keypad to go straight to a number.
- **Hymn page** — big readable words, verse numbers, refrains, A− / A+ text size, previous / next, heart to favourite. Tap the big hymn number to jump to another.
- **Background colours** — the palette button on the hymnal and on every hymn: Parchment, Dusk, Olive grove, Galilee, Desert sand, Sharon rose, Royal and six soft solids. Colours stay readable in both light and dark.
- **Sharing** — share a hymn as text, as a 4:5 picture card (Instagram-post size) in the hymn's colour, copy the words, or copy its Hymnary.org link. Long-press any verse to share just that verse.
- **Topics** — hymn of the day, and the book's 13 parts (Worship, Jesus Christ, Christian Life…) with their topics.
- **Favourites** and **Recent** tabs.
- **Type** — Newsreader (a serif, for titles, hymn numbers and the words) with Plus Jakarta Sans for everything you tap.
- **Settings** — laid out like Instagram's: search, grouped sections, values on the right. Appearance (system, light, dark), hymn background, text and reading (size, serif or sans, line spacing, verse numbers, refrain after every verse, keep screen on), haptics, hymn history, about, licences.
- **Opening screen** — the SDA logo (the phone's splash), then "by Mojo".

## Words and copyright

The words are in the app for the 502 hymns whose texts are in the public domain. The other 193 (modern texts and translations still under copyright) show their title and author and link to the hymn on Hymnary.org — the same rule as the SDA app. Hymn data: `assets/data/hymns.json`.

## Run it

```bash
npm install
npx expo start
```

Then press **i** for the iPhone Simulator, or scan the QR code with Expo Go.

Bundle id / package: `com.mojo.sdahymnal`.

## TestFlight

Every push to `main` builds and uploads to TestFlight through GitHub Actions. One-time setup (an API key secret, and creating the app in App Store Connect) is in [TESTFLIGHT.md](TESTFLIGHT.md).

## Layout

```
app/(tabs)/          Hymnal, Topics, Favourites, Recent, Settings
app/hymn/[number]    one hymn
app/part/[index]     one part of the book
app/prefs/           settings pages
src/components/      UI kit, photo banner, tab bar, colour sheet, share card
src/lib/             hymn data, saved settings, colours, theme
```
