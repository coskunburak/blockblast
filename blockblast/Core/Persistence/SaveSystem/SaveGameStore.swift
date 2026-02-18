import Foundation

enum SaveGameStoreError: Error {
    case encodeFailed
    case decodeFailed
}

protocol SaveGameStoreProtocol {
    func save(_ state: GameState) throws
    func load() throws -> GameState?
    func clear()
}

final class SaveGameStore: SaveGameStoreProtocol {
    private let keyValueStore: KeyValueStore
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        key: String = "com.blockblast.savegame"
    ) {
        self.keyValueStore = keyValueStore
        self.key = key
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ state: GameState) throws {
        let dto = SaveGameDTO(
            version: SaveMigrations.currentVersion,
            savedAt: Date(),
            state: state
        )
        guard let data = try? encoder.encode(dto) else {
            throw SaveGameStoreError.encodeFailed
        }
        keyValueStore.set(data, forKey: key)
    }

    func load() throws -> GameState? {
        guard let data = keyValueStore.data(forKey: key) else {
            return nil
        }
        guard let dto = try? decoder.decode(SaveGameDTO.self, from: data) else {
            throw SaveGameStoreError.decodeFailed
        }
        return SaveMigrations.migrateIfNeeded(dto).state
    }

    func clear() {
        keyValueStore.removeValue(forKey: key)
    }
}
