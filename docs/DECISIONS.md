# Architecture Decisions

> Log of significant technical choices. Add a new entry whenever a non-obvious decision is made.
> Format: context → decision → consequences.

---

## 2026-02-20 — Static JSON over live API

**Context:** The app needs 730+ chess games with metadata and precomputed positions.

**Decision:** Bundle `games.json` directly in the app binary. No network calls at runtime.

**Consequences:**
- App works offline, no server costs, instant load
- Updating the game database requires an app update
- ~3–5 MB added to app size (acceptable)
- Future: can migrate to API in a later version without changing the display logic

---

## 2026-02-20 — FEN strings precomputed by Python pipeline

**Context:** Displaying the correct board position requires knowing where each piece is. This could be computed at runtime by replaying PGN moves, or precomputed ahead of time.

**Decision:** Python pipeline (`build_json.py`) precomputes the 12 FEN strings per game. The app reads FEN strings directly from `games.json`.

**Consequences:**
- Zero chess logic at runtime — no engine, no PGN parser in Swift
- FEN → 8×8 array is a simple string split (~20 lines)
- Pipeline is one-time; results are baked into the bundle
- If a FEN is wrong, fix it in the pipeline and regenerate `games.json`

---

## 2026-02-20 — PGN Mentor as primary game source

**Context:** Need 730+ famous professional chess games with player names, ELO, and tournament info.

**Decision:** Download player PGN archives from pgnmentor.com (free, no API key). Parse with `python-chess`.

**Consequences:**
- Lichess open database rejected — it contains online blitz games, not famous OTB tournament games
- PGN Mentor has pre-curated player archives (Kasparov, Fischer, Carlsen, etc.) with clean metadata
- Historical ELO (pre-1970) may be `"?"` for some players — displayed as-is
- python-chess is GPL-3 but used only in pipeline scripts, not bundled in the app (app stays MIT)

---

## 2026-02-20 — cburnett PNG set for chess pieces

**Context:** Need chess piece images that are free to use and look clean.

**Decision:** Use the cburnett piece set, available as public domain on Wikimedia Commons.

**Consequences:**
- Public domain — no licensing concerns
- Industry standard: same set used by Lichess
- PNG format: simpler than SVG for SwiftUI on macOS
- 12 files: wK wQ wR wB wN wP bK bQ bR bB bN bP

---

## 2026-02-20 — MenuBarExtra for menu bar integration

**Context:** The app should behave like a widget — no dock icon, lives in the menu bar.

**Decision:** Use SwiftUI `MenuBarExtra` (macOS 13+). Pure SwiftUI, no AppKit required.

**Consequences:**
- Requires macOS 13 (Ventura) minimum — sets the OS floor
- No dock icon by default (set `LSUIElement = YES` in Info.plist as backup)
- Clean, modern approach — no legacy NSStatusItem code
- WidgetKit widget (future) would add $99 Apple Developer requirement — deferred

---

## 2026-02-20 — Zero Swift Package Manager dependencies

**Context:** Could use third-party libraries for chess board rendering, PGN parsing, etc.

**Decision:** No third-party Swift packages. Build everything needed from scratch.

**Consequences:**
- No dependency version conflicts, no SPM resolution issues
- Chess board rendering is a 8×8 `LazyVGrid` — ~100 lines
- FEN parsing is a string split — ~20 lines
- PGN is handled entirely in Python pipeline
- Simpler onboarding for future contributors

---

## 2026-02-20 — Checkmate-terminated games only

**Context:** The app claims positions are "N moves before the end." This is most meaningful if the game ended decisively.

**Decision:** Filter game database to only include games that ended in checkmate (verified by python-chess, not just PGN headers).

**Consequences:**
- Eliminates games ending by resignation, time, or draw
- Ensures the final position is always a decisive checkmate
- Reduces the raw pool of games but 730 checkmate games from famous players is very achievable
- Makes the "N moves before end" narrative accurate and interesting

---

## 2026-02-21 — Deterministic game selection (same game for everyone)

**Context:** `GameScheduler` uses `halfDayIndex % library.games.count` — a fully deterministic mapping from date+AM/PM to a game. This means every device shows the same game on the same day (like Wordle). User feedback after v0.1.0: this was surprising but not necessarily wrong.

**Decision:** Keep deterministic behavior in v0.1.0. Plan per-device seed offset for v0.2.0 (N6 in TODO.md). Seed stored in `UserDefaults` on first launch; same device always returns same game for same date. Different devices diverge.

**Consequences:**
- The "everyone sees the same game" Wordle-like property is lost with the seed offset — a deliberate tradeoff
- Social sharing of a specific position ("can you tell what time this is?") becomes harder once per-device randomization is added
- Seed offset is additive and non-breaking; determinism is preserved per-device
- If we ever want Wordle-mode back, it's a settings toggle (seed = 0 for all devices)

---

## 2026-02-20 — Square ring for minutes (not circular, not eval bar)

**Context:** Need a visual for minutes that fits in a compact square widget alongside the board.

**Decision:** A thin square border that traces the board's outer perimeter clockwise (top → right → bottom → left), filled proportionally to the current minute (0 = empty, 59 = full).

**Consequences:**
- Keeps the app layout square and compact
- No second board needed
- Visually distinct from any chess element — no confusion with the board
- Implemented as a SwiftUI custom `Shape` with `trim(from:to:)`
- Future: eval bar or two-board layout are preserved as FUTURE.md options
