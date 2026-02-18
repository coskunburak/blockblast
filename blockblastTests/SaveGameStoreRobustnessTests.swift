import Foundation
import Testing
@testable import blockblast

struct SaveGameStoreRobustnessTests {
    @Test func loadThrowsDecodeErrorForCorruptedPayload() {
        let key = "test.corrupted.save"
        let keyValue = InMemoryKeyValueStore()
        keyValue.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: key)
        let store = SaveGameStore(keyValueStore: keyValue, key: key)

        #expect(throws: SaveGameStoreError.decodeFailed) {
            _ = try store.load()
        }
    }

    @Test func migrationBumpsLegacyVersionToCurrent() {
        let state = GameState.initial(
            mode: .classic,
            gridSize: 8,
            seed: 2026,
            tuning: .classicDefault
        )
        let legacyDTO = SaveGameDTO(version: 0, savedAt: Date(), state: state)

        let migrated = SaveMigrations.migrateIfNeeded(legacyDTO)

        #expect(migrated.version == SaveMigrations.currentVersion)
        #expect(migrated.state == state)
    }
}
