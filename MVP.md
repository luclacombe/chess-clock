# MVP Specification — Chess Clock

> **This file is frozen.** Do not modify it once development begins.
> It defines what "done" means for v0.1.0.

---

## What the MVP Is

A macOS menu bar app that tells the time using real professional chess game positions.

- **Hour (1–12):** Shows a board position from a famous pro game, N moves before it ended in checkmate — where N equals the current hour
- **Minute (0–59):** A thin square ring traces the board's outer perimeter clockwise, filling proportionally
- **AM/PM:** A sun (AM) or moon (PM) icon with text label
- **Game info:** White player, Black player, ELO (both), Tournament, Year — always visible
- **Game rotation:** Deterministic by calendar date; AM and PM cycles each show a different game; same game displays all hour within its cycle

---

## MUST HAVE Features

| # | Feature |
|---|---|
| M1 | Chess board renders correctly from any FEN string |
| M2 | Hour N → board position N moves before game end |
| M3 | Square minute ring fills clockwise (0 = empty, 59 = full perimeter) |
| M4 | AM/PM indicator matches system clock |
| M5 | Game info strip: White, Black, ELO×2, Tournament, Year |
| M6 | Deterministic game rotation (AM and PM = different games per day) |
| M7 | 730+ checkmate-terminated games bundled as static JSON |
| M8 | Menu bar app: no dock icon, click to show/hide floating window |
| M9 | Distributable as .dmg, runs on macOS 13+ without Xcode |

---

## Success Criteria — Definition of Done

**The MVP is complete when ALL 9 pass with no regressions:**

```
[ ] S1  App launches from menu bar on a clean macOS 13+ machine (no Xcode installed)
[ ] S2  Correct chess position for current hour — manually verified against 3 published
        game diagrams from known games in the database
[ ] S3  Square ring: minute 0 = empty border, minute 30 = 50% fill, minute 59 = full
[ ] S4  AM/PM indicator matches system clock (checked at both AM and PM)
[ ] S5  Game info strip shows non-empty values for White, Black, ELO, Tournament, Year
[ ] S6  Mocking two different calendar dates shows two different games
[ ] S7  Game switches correctly at noon and midnight (mocked date test)
[ ] S8  DMG installs cleanly; app runs without Gatekeeper blocking
[ ] S9  No crashes observed during a 30-minute continuous run
```

**When all 9 are checked → tag v0.1.0 → attach DMG to GitHub Release → MVP shipped.**

---

## What Is NOT in the MVP

The following are explicitly out of scope for v0.1.0:

- Animation when the hour changes
- Settings panel of any kind
- Hide-the-time / guess-the-time mode
- Shareable screenshot feature
- Multiple piece themes or board color themes
- WidgetKit widget
- Light/dark theme control
- Network calls of any kind at runtime
- App Store listing
- Windows / Android / iOS versions

See `MAP.md` for NICE TO HAVE and NEXT VERSION features.

---

## Technical Constraints

- **Language:** Swift 5.9+
- **UI:** SwiftUI only (no AppKit except where MenuBarExtra requires it)
- **Minimum OS:** macOS 13 (Ventura)
- **Distribution:** GitHub Releases, .dmg, no App Store
- **No third-party Swift packages**
- **No network calls at runtime**
