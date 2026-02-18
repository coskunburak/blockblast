import Foundation

final class GameEngine {
    private(set) var state: GameState
    private let saveStore: SaveGameStoreProtocol?
    private let autoSaveEnabled: Bool

    init(
        initialState: GameState,
        saveStore: SaveGameStoreProtocol? = nil,
        autoSaveEnabled: Bool = true
    ) {
        self.state = initialState
        self.saveStore = saveStore
        self.autoSaveEnabled = autoSaveEnabled
    }

    @discardableResult
    func dispatch(_ action: GameAction) -> [GameEvent] {
        let previousState = state
        let events = GameReducer.reduce(state: &state, action: action)

        if autoSaveEnabled,
           previousState != state,
           let saveStore {
            try? saveStore.save(state)
        }

        return events
    }

    func saveNow() throws {
        try saveStore?.save(state)
    }

    @discardableResult
    func restoreLastGameIfAvailable() throws -> Bool {
        guard let loaded = try saveStore?.load() else {
            return false
        }
        state = loaded
        return true
    }

    func clearSavedGame() {
        saveStore?.clear()
    }
}
