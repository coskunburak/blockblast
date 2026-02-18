# Phase 1 - Gameplay Engine and Tests

## Delivered
- UI-independent gameplay engine (`GameEngine` + reducer flow).
- Placement rules with edge-case validation.
- Clear algorithm for full row/column wipes.
- Combo + streak scoring with configurable tuning.
- Fair piece generation (`PieceBag`) with drought guard for `dot1`.
- Remote-config-ready `DifficultyTuning` model.
- Game-over detection when no upcoming piece has valid placement.
- Save/load support for full `GameState` snapshot with migration hook.
- Unit tests covering placement, scoring/combo, no-move detection, bag fairness, and save/load.

## Core Contracts
- `GameAction -> GameReducer -> GameState + [GameEvent]`
- All domain models are `Codable` for persistence.
- Tuning is part of state to preserve run reproducibility.

## Persistence
- `SaveGameStoreProtocol` abstracts storage.
- `SaveGameStore` serializes `SaveGameDTO` via `JSONEncoder/Decoder`.
- `SaveMigrations` centralizes save version upgrades.

## Fairness Policy
- Shuffled bag over full piece set.
- Drought guard injects `dot1` if missing longer than `maxDot1Drought`.
- Run-length guard prevents too many identical consecutive kinds.

## Test Checklist Mapping
- Placement edge cases: `PlacementRulesTests.swift`
- Clear/combo scoring: `ScoringComboTests.swift`
- No possible move: `GameOverDetectionTests.swift`
- Bag fairness: `PieceBagFairnessTests.swift`
- Save/load continuity: `SaveLoadGameStateTests.swift`
- Clear line exactness: `ClearRulesTests.swift`
- Reducer flow invariants (place/refill + pause/resume): `GameReducerFlowTests.swift`
- Persistence robustness (corrupt payload + migration): `SaveGameStoreRobustnessTests.swift`

## Production Readiness Gate (2026-02-12)
- Scope completeness: PASS
- Engine/UI decoupling: PASS
- Deterministic core contracts: PASS
- Persistence + migration hooks: PASS
- Fairness controls (`dot1` drought + run-length): PASS
- Automated test execution in this environment: PASS

### Validation Runs
- Unit tests: `xcodebuild test ... -only-testing:blockblastTests` -> PASS
- UI tests: `xcodebuild test ... -only-testing:blockblastUITests` -> PASS
- Static analysis: `xcodebuild analyze ...` -> PASS
- Release build: `xcodebuild build -configuration Release ...` -> PASS

### Phase 2 Go/No-Go
- Decision: **GO**
- Technical implementation status of Phase 1: **PRODUCTION-READY** under current verification scope.
