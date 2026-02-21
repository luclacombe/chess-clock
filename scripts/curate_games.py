import os
import chess.pgn

RAW_DIR = os.path.join(os.path.dirname(__file__), "raw")
OUTPUT = os.path.join(os.path.dirname(__file__), "curated_games.pgn")
MAX_GAMES = 730

pgn_files = sorted(f for f in os.listdir(RAW_DIR) if f.endswith(".pgn"))
print(f"Found {len(pgn_files)} PGN files in scripts/raw/")

seen = set()
games = []

for filename in pgn_files:
    path = os.path.join(RAW_DIR, filename)
    file_games = 0
    file_checkmates = 0
    with open(path, encoding="utf-8", errors="replace") as f:
        while True:
            try:
                game = chess.pgn.read_game(f)
            except Exception:
                continue
            if game is None:
                break
            file_games += 1
            try:
                board = game.board()
                for move in game.mainline_moves():
                    board.push(move)
                if not board.is_checkmate():
                    continue
            except Exception:
                continue
            white = game.headers.get("White", "?")
            black = game.headers.get("Black", "?")
            date = game.headers.get("Date", "?")
            round_ = game.headers.get("Round", "?")
            key = (white.strip(), black.strip(), date.strip(), round_.strip())
            if key in seen:
                continue
            seen.add(key)
            games.append(game)
            file_checkmates += 1
    print(f"  {filename}: {file_games} total, {file_checkmates} checkmates added")

print(f"\nTotal checkmate games before cap: {len(games)}")

if len(games) > MAX_GAMES:
    step = len(games) / MAX_GAMES
    selected = [games[int(i * step)] for i in range(MAX_GAMES)]
else:
    selected = games

with open(OUTPUT, "w", encoding="utf-8") as out:
    exporter = chess.pgn.FileExporter(out)
    for game in selected:
        game.accept(exporter)

print(f"Output: {len(selected)} games written to scripts/curated_games.pgn")
