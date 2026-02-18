import Foundation

protocol KeyValueStore {
    func data(forKey key: String) -> Data?
    func set(_ value: Data, forKey key: String)
    func removeValue(forKey key: String)
}

struct UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func set(_ value: Data, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ value: Data, forKey key: String) {
        storage[key] = value
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
