# scripts/ — Data Pipeline

These scripts are **not shipped in the app**. They run once at build time to produce `games.json`, which is bundled into the Xcode project.

---

## Pipeline Order

```
fetch_games.py → curate_games.py → build_json.py → copy to ChessClock/Resources/
```

Run them in sequence from the repo root:

```bash
cd scripts
pip install -r requirements.txt
python fetch_games.py
python curate_games.py
python build_json.py
cp games.json ../ChessClock/ChessClock/Resources/games.json
```

---

## Files

### `fetch_games.py`
Downloads PGN game archives from pgnmentor.com for 15 hardcoded grandmasters (Kasparov, Fischer, Karpov, Carlsen, Anand, Tal, Botvinnik, Morphy, Capablanca, Alekhine, Kramnik, Petrosian, Spassky, Bronstein, Smyslov). Each player's zip is downloaded and extracted to `scripts/raw/{Player}.pgn`. Already-present files are skipped (safe to re-run).

**Output:** `scripts/raw/*.pgn` (15 files)

### `curate_games.py`
Reads all PGN files from `scripts/raw/`, replays each game with `python-chess`, and keeps only games that end in checkmate. Deduplicates by (White, Black, Date, Round). Caps at 730 games via uniform sampling if over the limit. Writes all selected games to a single PGN file.

**Output:** `scripts/curated_games.pgn` (~588 games — checkmate filter is strict)

### `build_json.py`
Reads `curated_games.pgn` and generates the final JSON bundle. For each game it extracts 12 FEN strings — the board positions at moves N−12 through N−1 before the final checkmate (where N is the total move count). `positions[0]` = 12 moves before the end (shown at hour 12); `positions[11]` = 1 move before the end (shown at hour 1). Extracts metadata: white, black, whiteElo, blackElo, tournament, year.

**Output:** `scripts/games.json` — array of game objects, each with 12 FEN strings

**After running:** manually copy to `ChessClock/ChessClock/Resources/games.json` to update the app bundle.

### `build_dmg.sh`
Builds the Release scheme via `xcodebuild archive`, attempts a developer-id export (requires a signing cert), falls back to copying `.app` directly from the archive if unsigned. Packages the result with `hdiutil` into a compressed DMG.

**Output:** `dist/ChessClock-{VERSION}.dmg`

**Note:** `VERSION` is hardcoded at the top of the script — update it before each release.

### `requirements.txt`
```
chess==1.10.0      # python-chess: PGN parsing and board replay
requests==2.31.0   # HTTP downloads in fetch_games.py
```

---

## Intermediate / Generated Files

| File | Created by | Committed? |
|---|---|---|
| `scripts/raw/*.pgn` | `fetch_games.py` | No (gitignored) |
| `scripts/curated_games.pgn` | `curate_games.py` | No |
| `scripts/games.json` | `build_json.py` | No — copy to Resources |
| `ChessClock/ChessClock/Resources/games.json` | Manual copy | Yes |

---

## Adding More Players

Edit the `PLAYERS` list in `fetch_games.py` and re-run the pipeline. The player name must match the filename on pgnmentor.com (e.g., `"Nakamura"` → `https://www.pgnmentor.com/players/Nakamura.zip`). Re-running `fetch_games.py` is safe — existing files are skipped.
