import os
import io
import zipfile
import requests

RAW_DIR = os.path.join(os.path.dirname(__file__), "raw")
BASE_URL = "https://www.pgnmentor.com/players/"
HEADERS = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}

PLAYERS = [
    "Kasparov", "Fischer", "Karpov", "Carlsen", "Anand",
    "Tal", "Botvinnik", "Morphy", "Capablanca", "Alekhine",
    "Kramnik", "Petrosian", "Spassky", "Bronstein", "Smyslov",
]

os.makedirs(RAW_DIR, exist_ok=True)

downloaded = 0
skipped = 0
failed = 0

for player in PLAYERS:
    out_path = os.path.join(RAW_DIR, f"{player}.pgn")
    if os.path.exists(out_path):
        print(f"[skip] {player}.pgn already exists")
        skipped += 1
        continue

    url = BASE_URL + player + ".zip"
    print(f"[fetch] {url}")
    success = False
    for attempt in range(2):
        try:
            resp = requests.get(url, timeout=30, headers=HEADERS)
            if resp.status_code == 404:
                print(f"  404 not found: {url}")
                break
            resp.raise_for_status()
            with zipfile.ZipFile(io.BytesIO(resp.content)) as zf:
                pgn_names = [n for n in zf.namelist() if n.lower().endswith(".pgn")]
                if not pgn_names:
                    print(f"  no .pgn in zip for {player}")
                    break
                with zf.open(pgn_names[0]) as src, open(out_path, "wb") as dst:
                    dst.write(src.read())
            print(f"  saved {player}.pgn")
            downloaded += 1
            success = True
            break
        except Exception as e:
            print(f"  attempt {attempt+1} error: {e}")
    if not success and not os.path.exists(out_path):
        failed += 1

pgn_files = [f for f in os.listdir(RAW_DIR) if f.endswith(".pgn")]
print(f"\nDone. downloaded={downloaded}, skipped={skipped}, failed={failed}")
print(f"Total .pgn files in scripts/raw/: {len(pgn_files)}")
