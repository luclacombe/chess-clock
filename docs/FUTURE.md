# Future Ideas

> A parking lot for ideas that are not MVP or MAP scope.
> Nothing here should be discussed, designed, or built until v0.1.0 ships.
> Ideas go here so they are never lost.

---

## UX / Display Ideas

### Eval bar for minutes (alternative to square ring)
Show a vertical evaluation bar on the side of the board. The bar height represents the current minute (0 = neutral center, growing toward one side as minutes increase). Fake — not a real engine evaluation. Looks like a chess UI native element.

### Two-board layout
One full board for the hour position, one miniature board (or strip) for the minute game. Shows a different famous game for minutes, also rewinding. Likely too busy for a compact widget but worth exploring for a "full window" mode.

### Annotated moves
After the clock ticks to a new hour, briefly display the move notation (e.g., "35. Rd7+") that was just "played." Could appear below the board for 3–5 seconds then fade out.

### Game move playback / cycling
Allow the user to manually step backward and forward through the 12 stored positions of the current game without the clock auto-advancing. Left/right arrow keys or on-screen chevron buttons. The challenge: stepping forward past the "current hour" position would reveal future moves (implying how many moves are left = current time). Design constraint: stepping backward should always be allowed; stepping forward past the current index should either be blocked or shown only in an explicit "reveal" mode. This is purely a display feature — no chess engine required, all positions are already in `games.json`. Not a priority; implement only after the core clock experience is polished.

### Game-chaining AM↔PM
When the clock switches from AM to PM cycle, the PM game features one player from the AM game. Example: if the AM game was Kasparov vs Anand, the PM game might be Anand vs Kramnik. Creates a narrative thread through the day.

### "Describe this position" mode
Small text below the board that describes the position: piece count, material balance, which side has the advantage. Generated from FEN at display time. Requires adding some lightweight chess evaluation logic.

---

## Technical / Platform Ideas

### Cross-platform versions
The app is currently macOS-only (SwiftUI). Future versions for other platforms would require full rewrites:
- **Windows:** .NET MAUI, WPF, or Electron
- **iOS / iPadOS:** SwiftUI (mostly reusable, but different MenuBar model)
- **Android:** Jetpack Compose or Flutter

Do not attempt until the macOS version is stable and has users.

### Online game database
Replace bundled `games.json` with live data:
- Lichess Broadcasts API for recent OTB games (clean PGN, good metadata)
- Own backend: curate games on a server, push updates without app releases
- Fallback to bundled games when offline

### WidgetKit widget
Native macOS widget for the Desktop / Notification Center. Identical layout to the floating window. Requires $99/year Apple Developer Program membership. Investigate if there's a way to do it without (there isn't — WidgetKit requires signing).

### Lichess-sourced live position
For users who want a live game: show the current position from an ongoing Lichess game (e.g., a Titled Tuesday tournament in progress). The clock shows a real live position, not a historical one. Very different product direction — a "live chess ticker" instead of a clock.

---

## Distribution / Community Ideas

### "Guess the time" share card (Wordle-style)
Show the board, user guesses hour and minute, then a shareable emoji/text card is generated. Copyable to clipboard. Designed for Twitter/Reddit chess communities. This is the primary viral growth mechanic.

### App Store listing
Would require $99/year Apple Developer account, code signing, notarization, and App Store review compliance. Worth doing after the open-source version gains traction.

### Player leaderboard
Users compete on how accurately they can guess the time from the position. Requires backend, accounts, and privacy considerations. Very long-term idea.

### Discord / Slack bot
Same concept as the app but as a bot: post the current position to a chess Discord, let members guess. Bot reveals the answer on the hour.

---

## Data Ideas

### Expanded game database (post-730)
Sources to explore for more games:
- **TWIC (The Week in Chess):** Weekly PGN archives since 1994, free, all major tournaments
- **Caissabase:** 4M+ free OTB games, downloadable, updated regularly
- **Lichess Broadcasts:** Clean PGN of recent OTB events rebroadcast on Lichess

### Thematic game selection
Instead of (or in addition to) rotating by date, let the app select games by theme:
- Today is a World Championship day (by historical date) → show a WC game
- Magnus Carlsen's birthday → show a Carlsen game
- Anniversary of a famous game (e.g., "Immortal Game" was July 21, 1851) → show it

### User-curated games
Let users add their own famous games (or personal games) to the rotation. Requires local file storage and a simple import UI.

---

## Piece Theme Ideas (future settings)

- **cburnett** (default, public domain) — classic Staunton
- **Merida** — widely used, clean
- **Alpha** — modern, minimal
- **Neo** — modern alternative
- **Pixel** — retro/fun

All these sets exist as open-source SVG/PNG collections.

---

## Board Color Theme Ideas (future settings)

- Classic green (Lichess default)
- Blue (chess.com)
- Tan / wood
- High-contrast (accessibility)
- Dark mode board (dark squares very dark, light squares off-white)
