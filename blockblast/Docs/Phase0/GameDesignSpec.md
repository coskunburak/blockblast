# Game Design Spec (Phase 0)

## Grid Size Decision
- Primary board: **8x8**
- Rationale: strongest Block Blast pacing with less dead time and higher tactical density.
- Future: 10x10 can be A/B tested through remote tuning.

## Piece Set
- Tetromino-inspired: `i4`, `o4`, `t4`, `l4`, `j4`, `s4`, `z4`
- Extras: `line3`, `square2`, `l3`, `dot1`

## Scoring
- Base score:
  - `clearedCells * 10 + clearedLines * 50`
- Combo bonus:
  - consecutive clear turns after first: `+30 * (comboCount - 1)`
- Streak bonus:
  - from third consecutive clear onward: `+20 * (streakCount - 2)`

## Modes
- `classic` (endless)
- `dailyChallenge` (daily objective shell)
- deferred: `timeAttack`, `puzzleLevels`
