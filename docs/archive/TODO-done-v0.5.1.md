# TODO Done — v0.5.1 (patch)

- [x] **Replay start position fix** — `puzzleStartPosIndex` formula corrected from `positions.count - 1` to `positions.count - 2`. Replay now opens at the true puzzle start (mating side to move, opponent's last move shown as context arrow). Previously opened one step too far forward at the checkmate position.
- [x] **GitHub Latest release** — Created formal GitHub Release for v0.5.1 via `gh release create --latest`, replacing the stale v0.4.0 Latest badge.
