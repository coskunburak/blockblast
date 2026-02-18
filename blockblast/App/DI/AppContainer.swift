import Combine
import Foundation

@MainActor
final class AppContainer {
    let environment: AppEnvironment
    let featureFlags: FeatureFlags

    let metaProgression: MetaProgressionStore
    let purchaseManager: PurchaseManager
    let remoteConfigClient: RemoteConfigClient
    let consentManager: ConsentManager
    let analyticsClient: AnalyticsClient
    let crashReporter: CrashReporter
    let rewardedAdManager: RewardedAdManager
    let interstitialAdManager: InterstitialAdManager
    let userPreferences: UserPreferencesStore

    private let saveStore: SaveGameStoreProtocol
    private var didBootstrapMonetization = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        environment: AppEnvironment = .current,
        featureFlags: FeatureFlags = .default,
        saveStore: SaveGameStoreProtocol = SaveGameStore(),
        keyValueStore: KeyValueStore = UserDefaultsStore()
    ) {
        self.environment = environment
        self.featureFlags = featureFlags
        self.saveStore = saveStore
        let remoteConfigClient = RemoteConfigClient(keyValueStore: keyValueStore)
        let userPreferences = UserPreferencesStore(keyValueStore: keyValueStore)
        let metaProgression = MetaProgressionStore(
            keyValueStore: keyValueStore,
            rewardedAdCoinsProvider: { [remoteConfigClient] in
                remoteConfigClient.currentMonetizationConfig.rewardedCoinAmount
            },
            dailyChallengeTuningProvider: { [remoteConfigClient] in
                remoteConfigClient.currentMonetizationConfig.gameplay.dailyChallenge
            }
        )
        let consentManager = ConsentManager(keyValueStore: keyValueStore)
        let analyticsClient = AnalyticsClient()
        let crashReporter = CrashReporter()

        self.metaProgression = metaProgression
        self.purchaseManager = PurchaseManager()
        self.remoteConfigClient = remoteConfigClient
        self.consentManager = consentManager
        self.analyticsClient = analyticsClient
        self.crashReporter = crashReporter
        self.rewardedAdManager = RewardedAdManager(
            configProvider: { [remoteConfigClient] in
                remoteConfigClient.currentMonetizationConfig
            },
            canRequestAds: { [consentManager] in
                consentManager.canRequestAds
            },
            analytics: analyticsClient
        )
        self.interstitialAdManager = InterstitialAdManager(
            meta: metaProgression,
            configProvider: { [remoteConfigClient] in
                remoteConfigClient.currentMonetizationConfig
            },
            canRequestAds: { [consentManager] in
                consentManager.canRequestAds
            },
            analytics: analyticsClient
        )
        self.userPreferences = userPreferences

        bindUserPreferences()
    }

    func makeGameEngine(mode: GameMode, seed: UInt64? = nil) -> GameEngine {
        let remoteGameplay = remoteConfigClient.currentMonetizationConfig.gameplay
        let remoteModeTuning: DifficultyTuning? = {
            switch mode {
            case .classic:
                return remoteGameplay.classicTuning
            case .dailyChallenge:
                return remoteGameplay.dailyTuning
            }
        }()

        let initialState = StartNewGame.makeInitialState(
            mode: mode,
            gridSize: environment.defaultGridSize,
            seed: seed,
            remoteTuning: remoteModeTuning
        )
        return GameEngine(initialState: initialState, saveStore: saveStore)
    }

    func bootstrapMonetizationIfNeeded() async {
        guard !didBootstrapMonetization else { return }
        didBootstrapMonetization = true

        crashReporter.start()
        await remoteConfigClient.refresh()
        await consentManager.prepareForLaunch()
        rewardedAdManager.warmupIfNeeded()
        interstitialAdManager.warmupIfNeeded()

        analyticsClient.track(
            AnalyticsFunnels.sessionStart(
                environment: environment,
                appVersion: Bundle.main.releaseVersion,
                build: Bundle.main.buildVersion
            )
        )
    }

    private func bindUserPreferences() {
        AudioEngine.shared.setEnabled(userPreferences.soundEnabled)
        HapticManager.shared.setEnabled(userPreferences.hapticsEnabled)

        userPreferences.$soundEnabled
            .removeDuplicates()
            .sink { enabled in
                AudioEngine.shared.setEnabled(enabled)
            }
            .store(in: &cancellables)

        userPreferences.$hapticsEnabled
            .removeDuplicates()
            .sink { enabled in
                HapticManager.shared.setEnabled(enabled)
            }
            .store(in: &cancellables)
    }
}

private extension Bundle {
    var releaseVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }

    var buildVersion: String {
        (infoDictionary?["CFBundleVersion"] as? String) ?? "0"
    }
}
