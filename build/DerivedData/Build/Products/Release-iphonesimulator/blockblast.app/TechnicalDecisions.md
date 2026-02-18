# Technical Decisions (Phase 0)

## Rendering + UI
- Gameplay: SpriteKit
- Menus/Meta UI: SwiftUI

## Architecture
- Engine Pattern: Reducer
  - `GameAction -> GameReducer -> GameState`
- UI reads state through `GameViewModel` and dispatches actions.

## Determinism
- Piece generation uses a seeded bag (`PieceBag`) to support reproducibility.

## Scope Boundaries
- Classic + Daily Challenge shipped in core domain.
- Time Attack/Puzzle modes are deferred behind flags.
