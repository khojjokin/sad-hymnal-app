# SDA Hymnal

All 695 hymns of the Seventh-day Adventist Hymnal (1985), numbered as in the printed book, for iPhone and Android. Works fully offline. By Mojo.

## What's in it

- **Hymnal** — the photo banner with the SDA logo, search by number, title, writer or first line, recently opened hymns, favourites, then every section in book order. The **#** button opens a keypad to go straight to a number.
- **Hymn page** — the hymn number large, clear serif words, verse numbers and refrains, A− / A+ text size, previous / next, favourite, share, and the story behind the hymn where there is one.
- **Discover** — laid out like the SDA app's Sabbath School page: hymn of the day, the story behind a hymn, a writer to meet, hymns for the morning, evening or Sabbath, and the book's parts. The button at the top right shows another set.
- **Sharing** — as text, as a sea-blue picture card, or copied. Long-press a verse to share just that verse.
- **Favourites** and **Settings** (appearance, language, favourites, share, rate, about, licences and credits).
- **Languages** — English, Español, Français, Português, Deutsch and Kiswahili for the app's menus and buttons.
- **Type** — Newsreader for the hymns and titles, Plus Jakarta Sans for the interface. Sea blue throughout.

## Words and copyright

The words are in the app for the 502 hymns whose texts are in the public domain. The other 193 (modern texts and translations still under copyright) show their title and author and link to the hymn on Hymnary.org — the same rule as the SDA app. Hymn data: `assets/data/hymns.json`.

## Run it

```bash
npm install
npx expo start
```

Then press **i** for the iPhone Simulator, or scan the QR code with Expo Go.

Bundle id / package: `com.mojo.sdahymnal`.

## App Store pictures

The **Store screenshots** workflow builds the web version of the app and photographs its screens at 1320 x 2868 (iPhone 6.9-inch), each under a headline. Download them from the run, or find them on the `ci-logs` branch under `screenshots/`.

## TestFlight

Every push to `main` builds and uploads to TestFlight through GitHub Actions. One-time setup (an API key secret, and creating the app in App Store Connect) is in [TESTFLIGHT.md](TESTFLIGHT.md).

## Layout

```
app/(tabs)/          Hymnal, Discover, Favourites, Settings
app/hymn/[number]    one hymn
app/part/[index]     one part of the book
app/prefs/           settings pages
src/components/      UI kit, photo banner, tab bar, share card
src/lib/             hymn data, saved settings, colours, theme
```
