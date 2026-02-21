# Chess Clock

A macOS menu bar app that tells the time using real professional chess game positions.

---

## What Is This?

Instead of showing you digits, Chess Clock shows you a board position from a famous grandmaster game:

- **The hour** is how many moves are left until the game ended in checkmate. At 3:xx, you see the board 3 moves before checkmate.
- **The minutes** fill a thin square ring around the board, clockwise.
- **The game rotates daily** — a different famous game every AM and PM cycle.
- **Game info** always shows: the two players, their ELOs, the tournament, and the year.

It's a clock for chess players who'd rather think about positions than read numbers.

---

## Screenshots

> _Screenshots will be added after v0.1.0 ships._

---

## Download

**[⬇ Download ChessClock-0.1.0.dmg](https://github.com/luclacombe/chess-clock/releases/download/v0.1.0/ChessClock-0.1.0.dmg)**

**Requirements:** macOS 13 (Ventura) or later.

### Install

1. Download `ChessClock-0.1.0.dmg` from the link above (or the [Releases page](https://github.com/luclacombe/chess-clock/releases))
2. Open the `.dmg` and drag **ChessClock** to your Applications folder
3. **First launch:** Right-click the app → **Open** (required — the app is not yet notarized)
4. The app lives in your menu bar with a ♛ crown icon — no Dock icon

---

## How It Works

### The Hour
Each day, the app selects two famous games from its database (one for AM, one for PM). These games all ended in checkmate.

At any given hour H (1–12), the app shows the board position that was H moves before the final checkmate. At 1:xx you're one move away. At 12:xx you're twelve moves away — the farthest back the clock goes.

### The Minutes
A thin border traces the edge of the board clockwise, starting from the top-left corner. At minute 0, the border is empty. At minute 59, the border is complete.

### AM / PM
A small sun icon means AM. A moon icon means PM. Simple.

### Game Rotation
Games are selected deterministically by date. Every day brings a new pair of games. After a full year (365 days, 730 games), the cycle repeats.

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
python curate_games.py     # Filters to 730 checkmate games
python build_json.py       # Outputs games.json with precomputed FEN strings
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

See [MAP.md](MAP.md) for planned features and [FUTURE.md](FUTURE.md) for longer-term ideas.

Current focus: shipping v0.1.0 (the MVP). See [TODO.md](TODO.md) for progress.

---

## Contributing

This is a portfolio project built with [Claude Code](https://claude.ai/claude-code). Issues and PRs welcome once v0.1.0 ships.
