import Testing
@testable import blockblast

@MainActor
struct UserPreferencesStoreTests {
    @Test func preferencesPersistAcrossInstances() {
        let keyValue = InMemoryKeyValueStore()
        let first = UserPreferencesStore(keyValueStore: keyValue)

        first.soundEnabled = false
        first.hapticsEnabled = false
        first.prefersLargeText = true
        first.highContrastMode = true
        first.language = .turkish

        let restored = UserPreferencesStore(keyValueStore: keyValue)
        #expect(restored.soundEnabled == false)
        #expect(restored.hapticsEnabled == false)
        #expect(restored.prefersLargeText == true)
        #expect(restored.highContrastMode == true)
        #expect(restored.language == .turkish)
    }

    @Test func dynamicTypeReflectsLargeTextPreference() {
        let prefs = UserPreferencesStore(keyValueStore: InMemoryKeyValueStore())

        prefs.prefersLargeText = false
        #expect(prefs.dynamicTypeSize == .large)

        prefs.prefersLargeText = true
        #expect(prefs.dynamicTypeSize == .accessibility2)
    }
}
