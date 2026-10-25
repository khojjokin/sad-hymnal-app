# SDA Hymnal

The Seventh-day Adventist Hymnal for iPhone, made by Qortn. Native SwiftUI, iOS 17 and up (Liquid Glass on iOS 26).

- **Hymnal**: all 695 hymns, search by title, words or number, number pad, parts of the book.
- **Hymn**: big serif words, text size, keep screen on, previous and next, the story behind it.
- **Share cards**: five looks (Sea, Sunrise, Night, Paper, Forest), three shapes (square, post, story), pick a verse, share or save to Photos.
- **Saved**: saved hymns and your own lists. Optional account (Clerk) keeps them on every device.
- **Discover**: hymn of the day, hymns for this moment, stories and writers, shuffle at the top right.
- **Settings**: account, appearance, language (6), text size, keep screen on, share, rate, credits. Made by Qortn.

Copyrighted words are not included; those hymns show title, writer and a Hymnary.org link.

## Backend
Supabase project `fjnifvugmbtajelmiuuh`, edge function `hymnal-api` (in `supabase/functions`). Managed from the Qortn Console.
Sign in: Clerk. `Backend.useLiveSignIn` switches from the development instance to `clerk.hymnal.qortyn.com` once its DNS is verified.

## Shipping
Builds go to TestFlight from Xcode on the Mac only (Product › Archive › Distribute App), or `./ship.sh`. GitHub only stores the code: no pipelines upload builds.
