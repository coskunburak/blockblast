import Testing
@testable import blockblast

struct PowerUpUsageTests {
    @Test func hammerRemovesSingleCell() {
        var grid = Grid(size: 8)
        let target = Cell(row: 3, column: 4)
        let untouched = Cell(row: 1, column: 1)
        grid.fill([target, untouched])

        let result = PowerUpUseService.applyHammer(on: grid, at: target)

        #expect(result.didApply)
        #expect(!result.grid.contains(target))
        #expect(result.grid.contains(untouched))
    }

    @Test func bombClearsThreeByThreeRegion() {
        var grid = Grid(size: 8)
        let center = Cell(row: 3, column: 3)
        let outside = Cell(row: 0, column: 0)
        var filledCells: [Cell] = [outside]

        for row in 2...4 {
            for column in 2...4 {
                filledCells.append(Cell(row: row, column: column))
            }
        }
        grid.fill(filledCells)

        let updated = PowerUpUseService.applyBomb(on: grid, center: center)

        for row in 2...4 {
            for column in 2...4 {
                #expect(!updated.contains(Cell(row: row, column: column)))
            }
        }
        #expect(updated.contains(outside))
    }

    @Test func rainbowSetsNextSpawnIsWildcard() {
        var state = makeState(seed: 11)
        let didAddRainbow = state.powerUpInventory.add(type: .rainbow)
        #expect(didAddRainbow)

        let events = GameReducer.reduce(state: &state, action: .selectPowerUp(type: .rainbow))

        #expect(events.contains(.powerUpSelected(.rainbow)))
        #expect(events.contains(.powerUpApplied(.rainbow)))
        #expect(state.nextSpawnIsWildcard)
        #expect(state.powerUpInventory.count(for: .rainbow) == 0)
        #expect(!state.isPowerUpModeActive)
    }

    @Test func inventoryDecrementsCorrectly() {
        var state = makeState(seed: 12)
        let didAddBomb = state.powerUpInventory.add(type: .bomb)
        #expect(didAddBomb)

        _ = GameReducer.reduce(state: &state, action: .selectPowerUp(type: .bomb))
        let events = GameReducer.reduce(state: &state, action: .tapBoard(position: Cell(row: 4, column: 4)))

        #expect(events.contains(.powerUpApplied(.bomb)))
        #expect(events.contains(.inventoryUpdated(.bomb, newCount: 0)))
        #expect(state.powerUpInventory.count(for: .bomb) == 0)
    }

    @Test func cannotUsePowerUpWhenInventoryEmpty() {
        var state = makeState(seed: 13)

        let events = GameReducer.reduce(state: &state, action: .selectPowerUp(type: .hammer))

        #expect(events.isEmpty)
        #expect(!state.isPowerUpModeActive)
        #expect(state.interactionState.selectedPowerUp == .none)
    }

    @Test func powerUpModeResetsAfterApply() {
        var state = makeState(seed: 14)
        let target = Cell(row: 2, column: 2)
        state.grid.fill([target])
        let didAddHammer = state.powerUpInventory.add(type: .hammer)
        #expect(didAddHammer)

        _ = GameReducer.reduce(state: &state, action: .selectPowerUp(type: .hammer))
        _ = GameReducer.reduce(state: &state, action: .tapBoard(position: target))

        #expect(!state.isPowerUpModeActive)
        #expect(state.interactionState.selectedPowerUp == .none)
    }

    @Test func cancelReturnsToNormalMode() {
        var state = makeState(seed: 15)
        let didAddBomb = state.powerUpInventory.add(type: .bomb)
        #expect(didAddBomb)

        _ = GameReducer.reduce(state: &state, action: .selectPowerUp(type: .bomb))
        let events = GameReducer.reduce(state: &state, action: .cancelPowerUpSelection)

        #expect(events.contains(.powerUpCancelled))
        #expect(!state.isPowerUpModeActive)
        #expect(state.interactionState.selectedPowerUp == .none)
    }

    @Test func wildcardFlagResetsAfterNextSpawn() {
        var state = makeState(seed: 16)
        state.nextSpawnIsWildcard = true
        state.upcomingPieces = []

        GenerateNextPieces.refillIfNeeded(state: &state)

        #expect(!state.upcomingPieces.isEmpty)
        #expect(state.upcomingPieces[0].kind == .dot1)
        #expect(state.nextSpawnIsWildcard == false)
    }

    private func makeState(seed: UInt64) -> GameState {
        StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: seed,
            remoteTuning: nil
        )
    }
}
