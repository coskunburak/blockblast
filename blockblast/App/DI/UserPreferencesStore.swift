import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case system
    case english
    case turkish

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .english:
            return "en"
        case .turkish:
            return "tr"
        }
    }

    var resourceCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .turkish:
            return "tr"
        }
    }
}

private struct UserPreferencesSnapshot: Codable {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var language: AppLanguage
    var prefersLargeText: Bool
    var highContrastMode: Bool

    static let `default` = UserPreferencesSnapshot(
        soundEnabled: true,
        hapticsEnabled: true,
        language: .system,
        prefersLargeText: false,
        highContrastMode: false
    )
}

@MainActor
final class UserPreferencesStore: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet { persist() }
    }

    @Published var hapticsEnabled: Bool {
        didSet { persist() }
    }

    @Published var language: AppLanguage {
        didSet { persist() }
    }

    @Published var prefersLargeText: Bool {
        didSet { persist() }
    }

    @Published var highContrastMode: Bool {
        didSet { persist() }
    }

    private let keyValueStore: KeyValueStore
    private let storageKey = "com.blockblast.preferences.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(keyValueStore: KeyValueStore = UserDefaultsStore()) {
        self.keyValueStore = keyValueStore

        if let data = keyValueStore.data(forKey: storageKey),
           let decoded = try? decoder.decode(UserPreferencesSnapshot.self, from: data) {
            soundEnabled = decoded.soundEnabled
            hapticsEnabled = decoded.hapticsEnabled
            language = decoded.language
            prefersLargeText = decoded.prefersLargeText
            highContrastMode = decoded.highContrastMode
        } else {
            let fallback = UserPreferencesSnapshot.default
            soundEnabled = fallback.soundEnabled
            hapticsEnabled = fallback.hapticsEnabled
            language = fallback.language
            prefersLargeText = fallback.prefersLargeText
            highContrastMode = fallback.highContrastMode
        }
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var dynamicTypeSize: DynamicTypeSize {
        prefersLargeText ? .accessibility2 : .large
    }

    var localizationBundle: Bundle {
        guard let code = language.resourceCode,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }

    func localized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: localizationBundle, value: key, comment: "")
    }

    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        if args.isEmpty {
            return format
        }
        return String(format: format, locale: locale, arguments: args)
    }

    private func persist() {
        let snapshot = UserPreferencesSnapshot(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            language: language,
            prefersLargeText: prefersLargeText,
            highContrastMode: highContrastMode
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        keyValueStore.set(data, forKey: storageKey)
    }
}
