# Chess Clock

A macOS menu bar app that tells the time using real professional chess game positions.

---

## What Is This?

Instead of showing you digits, Chess Clock shows you a board position from a famous grandmaster game:

- **The hour** is how many moves are left until the game ended in checkmate. At 3:xx, you see the board 3 moves before checkmate.
- **The minutes** fill a thin square ring around the board, clockwise from 12 o'clock.
- **The game rotates every hour** — a different famous game each hour, unique to your device.
- **AM / PM** is encoded in the board orientation: White's perspective (rank 1 at bottom) means AM; Black's perspective (board flipped) means PM.
- **Tap the board** to see game info: the two players, their ELOs, the tournament, round, and date.
- **Guess the move** — after tapping, challenge yourself to find the actual checkmate move that won the game.

It's a clock for chess players who'd rather think about positions than read numbers.

---

## Screenshots

> _Screenshots coming soon._

---

## Download

**[⬇ Download ChessClock-0.3.0.dmg](https://github.com/luclacombe/chess-clock/releases/download/v0.3.0/ChessClock-0.3.0.dmg)**

**Requirements:** macOS 13 (Ventura) or later.

### Install

1. Download `ChessClock-0.3.0.dmg` from the link above (or the [Releases page](https://github.com/luclacombe/chess-clock/releases))
2. Open the `.dmg` and drag **ChessClock** to your Applications folder
3. **First launch:** Right-click the app → **Open** (required — the app is not yet notarized)
4. The app lives in your menu bar with a ♛ crown icon — no Dock icon

---

## How It Works

### The Hour
Each hour, the app selects a new famous game from its database. These games all ended in checkmate.

At any given hour H (1–12), the app shows the board position that was H moves before the final checkmate. At 1:xx you're one move away. At 12:xx you're twelve moves away — the farthest back the clock goes.

### The Minutes
A thin border traces the edge of the board clockwise, starting from the top-center (12 o'clock). At minute 0, the border is empty. At minute 59, the border is complete.

### AM / PM
The board flips. AM shows the position from White's point of view (rank 1 at the bottom). PM shows it from Black's point of view (rank 8 at the bottom). No icons — the board perspective is the indicator.

### Game Rotation
A new game appears every hour. Games are selected by a per-device seed generated on first launch — every device gets its own unique rotation, but the same game always appears at the same hour on the same device.

### Guess the Move
Tap the board to open the info panel, then press **Guess Move** to open an interactive puzzle. The board shows the position one move before the final checkmate. Drag or click pieces to make your move. After guessing, you'll see whether you matched the actual finishing move. One guess per hour — a new puzzle resets at the top of every hour.

### Keyboard Shortcut
Press **⌥Space** (Option + Space) from any app to show or hide the clock window without clicking the menu bar.

### Floating Window
Click the **⋯** icon in the menu bar to open Chess Clock as a persistent floating panel — always on top, stays visible while you use other apps.

---

## Building from Source

**Requirements:**
- macOS 13+
- Xcode 15+
- Python 3.10+ (for data pipeline only)

```bash
# Clone the repo
git clone https://github.com/luclacombe/chess-clock.git
cd chess-clock

# Open in Xcode
open ChessClock/ChessClock.xcodeproj

# Build (⌘B) and run (⌘R) in Xcode
```

### Regenerating the game database

```bash
cd scripts
pip install -r requirements.txt
python fetch_games.py      # Downloads PGNs from PGN Mentor
python curate_games.py     # Filters to checkmate games
python build_json.py       # Outputs games.json with precomputed FEN strings and final moves
```

Then replace `ChessClock/Resources/games.json` with the new file.

---

## Game Sources

Games are sourced from [PGN Mentor](https://www.pgnmentor.com/) — a free archive of professional chess games. All games used ended in checkmate and feature famous grandmasters including Kasparov, Fischer, Carlsen, Nakamura, Anand, Kramnik, Karpov, Tal, and others.

Chess piece images are the [cburnett set](https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces/Standard_design), released to the public domain.

---

## License

MIT — see [LICENSE](LICENSE).

The Python pipeline uses [python-chess](https://github.com/niklasf/python-chess) (GPL-3) for PGN parsing. The library is used only in the data pipeline scripts and is not bundled in the app.

Chess piece images (cburnett set) are public domain.

---

## Roadmap

See [docs/MAP.md](docs/MAP.md) for planned features and [docs/FUTURE.md](docs/FUTURE.md) for longer-term ideas.

---

## Contributing

This is a portfolio project built with [Claude Code](https://claude.ai/claude-code). Issues and PRs welcome.
