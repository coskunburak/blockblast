# Core Loop

## Loop
1. Place Piece
2. Resolve Clears (row/column)
3. Apply Combo + Streak Bonuses
4. Refill Upcoming Pieces
5. Check Game Over

## Reducer Flow
- Input: `GameAction`
- Processing: `GameReducer.reduce(state:action:)`
- Output: new `GameState` + `GameEvent[]`

## Runtime States
- `running`
- `paused`
- `gameOver`
