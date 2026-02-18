import Foundation

@MainActor
protocol MonetizationConfigProviding: AnyObject {
    var currentMonetizationConfig: MonetizationRemoteConfig { get }
    func refresh() async
}

@MainActor
final class RemoteConfigClient: ObservableObject, MonetizationConfigProviding {
    @Published private(set) var currentMonetizationConfig: MonetizationRemoteConfig

    private let keyValueStore: KeyValueStore
    private let installationIDKey = "com.blockblast.remote.installation_id"

    init(
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        initialConfig: MonetizationRemoteConfig = .fallback
    ) {
        self.keyValueStore = keyValueStore
        self.currentMonetizationConfig = initialConfig
        self.currentMonetizationConfig = RemoteTuning.productionMonetization(for: installationID())
    }

    func refresh() async {
        // Simulates fetch latency and allows future server implementation behind same contract.
        try? await Task.sleep(nanoseconds: 120_000_000)
        currentMonetizationConfig = RemoteTuning.productionMonetization(for: installationID())
    }

    private func installationID() -> String {
        if let data = keyValueStore.data(forKey: installationIDKey),
           let id = String(data: data, encoding: .utf8),
           !id.isEmpty {
            return id
        }

        let newID = UUID().uuidString
        keyValueStore.set(Data(newID.utf8), forKey: installationIDKey)
        return newID
    }
}
