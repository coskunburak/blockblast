import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    struct LiveObjective: Equatable {
        let title: String
        let subtitle: String
        let progress: Int
        let target: Int
        let rewardCoins: Int
    }

    @Published private(set) var state: GameState
    @Published private(set) var recentEvents: [GameEvent] = []
    @Published private(set) var dispatchSerial: Int = 0
    @Published var rewardBanner: String?
    @Published var comboBanner: String?
    @Published private(set) var activeObjective: LiveObjective?
    @Published var objectiveBanner: String?
    @Published var showAhaCoachmark: Bool = false
    @Published var monetizationToast: String?
    @Published var activePaywall: PaywallViewModel?
    @Published private(set) var totalGameOvers: Int = 0
    @Published private(set) var rewardedContinuesUsedThisRun: Int = 0
    @Published private(set) var latestResultSummary: GameResultSummary?

    private let engine: GameEngine
    private let meta: MetaProgressionStore
    private let interstitialAds: InterstitialAdManager
    private let rewardedAds: RewardedAdManager
    private let purchaseManager: PurchaseManager
    private let remoteConfig: MonetizationConfigProviding
    private let analytics: AnalyticsTracking?
    private let crashReporter: CrashReporting?
    private var cancellables: Set<AnyCancellable> = []
    private var runStartedAt: Date
    private var runClears: Int = 0
    private var runComboMax: Int = 1
    private var didTrackFirstClearTutorial = false
    private var objectiveTier: Int = 1
    private var objectiveCompletions: Int = 0
    private var objectiveRuntime: RuntimeObjective?

    init(
        engine: GameEngine,
        meta: MetaProgressionStore,
        interstitialAds: InterstitialAdManager,
        rewardedAds: RewardedAdManager,
        purchaseManager: PurchaseManager,
        remoteConfig: MonetizationConfigProviding,
        analytics: AnalyticsTracking? = nil,
        crashReporter: CrashReporting? = nil
    ) {
        self.engine = engine
        self.meta = meta
        self.interstitialAds = interstitialAds
        self.rewardedAds = rewardedAds
        self.purchaseManager = purchaseManager
        self.remoteConfig = remoteConfig
        self.analytics = analytics
        self.crashReporter = crashReporter
        self.runStartedAt = Date()
        self.state = engine.state

        do {
            _ = try engine.restoreLastGameIfAvailable()
        } catch {
            crashReporter?.record(
                error: error,
                context: "restore_saved_game",
                attributes: ["screen": "game"]
            )
        }
        self.state = engine.state

        bindDependencies()

        meta.beginRun()
        interstitialAds.warmupIfNeeded()
        rewardedAds.warmupIfNeeded()

        trackGameStart()
        refreshAhaCoachmark()
        generateNextObjective(resetProgression: true)
    }

    var equippedThemes: (block: ThemeDefinition?, grid: ThemeDefinition?) {
        (meta.equippedBlockTheme(), meta.equippedGridTheme())
    }

    var coins: Int {
        meta.coins
    }

    var isPowerUpModeActive: Bool {
        state.isPowerUpModeActive
    }

    var selectedPowerUpType: PowerUpType? {
        state.selectedPowerUpType
    }

    var validTargetPositions: Set<Cell> {
        state.validTargetPositions
    }

    var canContinueWithRewardedAd: Bool {
        guard state.runtime == .gameOver else { return false }
        let config = remoteConfig.currentMonetizationConfig
        let allowedContinues = max(0, config.rewardedContinueLimitPerRun)
        guard rewardedContinuesUsedThisRun < allowedContinues else { return false }
        return rewardedAds.canPresent(placement: .continueRun)
    }

    var canClaimGameOverCoinsWithAd: Bool {
        guard state.runtime == .gameOver else { return false }
        guard meta.timeUntilRewardedAdReady() <= 0 else { return false }
        return rewardedAds.canPresent(placement: .bonusCoins)
    }

    var canOpenGameOverOffer: Bool {
        state.runtime == .gameOver && !meta.removeAdsEnabled
    }

    var continueButtonTitle: String {
        if rewardedAds.isShowing {
            return "Watching..."
        }
        let remaining = rewardedAds.cooldownRemainingSeconds()
        if remaining > 0 {
            return "Continue \(remaining)s"
        }
        if rewardedContinuesUsedThisRun >= max(0, remoteConfig.currentMonetizationConfig.rewardedContinueLimitPerRun) {
            return "Continue Used"
        }
        if !rewardedAds.isReady {
            return rewardedAds.isLoading ? "Continue Loading..." : "Continue +Ad"
        }
        return "Continue +Ad"
    }

    var coinRewardButtonTitle: String {
        let rewardAmount = meta.rewardedAdCoinAmount
        if rewardedAds.isShowing {
            return "Watching..."
        }

        let economyRemaining = Int(meta.timeUntilRewardedAdReady().rounded(.up))
        if economyRemaining > 0 {
            return "Coins \(economyRemaining)s"
        }

        let cooldownRemaining = rewardedAds.cooldownRemainingSeconds()
        if cooldownRemaining > 0 {
            return "Coins \(cooldownRemaining)s"
        }

        if !rewardedAds.isReady {
            return rewardedAds.isLoading ? "Coins Loading..." : "Coins +\(rewardAmount)"
        }

        return "Coins +\(rewardAmount)"
    }

    func placePiece(id: Piece.ID, at cell: Cell) {
        let previousState = state
        let events = engine.dispatch(.placePiece(pieceID: id, anchor: cell))
        state = engine.state
        recentEvents = events
        dispatchSerial += 1

        handleGameplayDispatch(previousState: previousState, events: events)
    }

    func selectPowerUp(type: PowerUpType) {
        let events = engine.dispatch(.selectPowerUp(type: type))
        state = engine.state
        recentEvents = events
        dispatchSerial += 1
    }

    func cancelPowerUpSelection() {
        let events = engine.dispatch(.cancelPowerUpSelection)
        state = engine.state
        recentEvents = events
        dispatchSerial += 1
    }

    func tapBoard(at cell: Cell) {
        let previousState = state
        let events = engine.dispatch(.tapBoard(position: cell))
        state = engine.state
        recentEvents = events
        dispatchSerial += 1

        handleGameplayDispatch(previousState: previousState, events: events)
    }

    private func handleGameplayDispatch(previousState: GameState, events: [GameEvent]) {
        guard !events.isEmpty else { return }

        advanceObjective(previousState: previousState, currentState: state, events: events)

        if events.contains(where: {
            if case .linesCleared = $0 { return true }
            return false
        }) {
            showAhaCoachmark = false
            runClears += events.reduce(into: 0) { partial, event in
                if case let .linesCleared(count) = event {
                    partial += count
                }
            }
            if !didTrackFirstClearTutorial {
                didTrackFirstClearTutorial = true
                analytics?.track(AnalyticsFunnels.tutorialStep(step: "first_clear", status: "completed"))
            }
        }

        let grants = meta.processGameplay(previous: previousState, current: state, events: events)
        if let topGrant = grants.last {
            rewardBanner = "+\(topGrant.coins) coins"
            AudioEngine.shared.play(.reward, minimumSpacing: 0.08)
        }

        if let comboPayload = events.compactMap({ event -> (multiplier: Int, chain: Int)? in
            if case let .comboTriggered(multiplier, chain) = event {
                return (multiplier, chain)
            }
            return nil
        }).last {
            comboBanner = comboBannerText(multiplier: comboPayload.multiplier, chain: comboPayload.chain)
            runComboMax = max(runComboMax, comboPayload.chain)
        } else {
            runComboMax = max(runComboMax, state.score.comboChain)
        }

        if events.contains(where: {
            if case .gameOver = $0 { return true }
            return false
        }) {
            handleGameOverFlow()
        }
    }

    func pause() {
        let events = engine.dispatch(.pause)
        state = engine.state
        recentEvents = events
        dispatchSerial += 1
    }

    func resume() {
        let events = engine.dispatch(.resume)
        state = engine.state
        recentEvents = events
        dispatchSerial += 1
    }

    func restart() {
        let events = engine.dispatch(.startNewGame(mode: state.mode, seed: nil))
        state = engine.state
        recentEvents = events
        dispatchSerial += 1

        rewardBanner = nil
        comboBanner = nil
        objectiveBanner = nil
        latestResultSummary = nil
        rewardedContinuesUsedThisRun = 0
        meta.beginRun()
        interstitialAds.warmupIfNeeded()
        rewardedAds.warmupIfNeeded()
        resetRunTelemetry()
        trackGameStart()
        refreshAhaCoachmark()
        generateNextObjective(resetProgression: true)
    }

    func continueWithRewardedAd() {
        guard canContinueWithRewardedAd else { return }

        Task {
            let watched = await rewardedAds.showAd(for: .continueRun)
            guard watched else {
                await MainActor.run {
                    monetizationToast = "Continue ad unavailable right now."
                }
                return
            }

            let events = engine.dispatch(.continueAfterGameOver)
            await MainActor.run {
                state = engine.state
                recentEvents = events
                dispatchSerial += 1
                if events.contains(.continuedFromGameOver) {
                    rewardedContinuesUsedThisRun += 1
                    latestResultSummary = nil
                    monetizationToast = "Second chance unlocked."
                    AudioEngine.shared.play(.reward, minimumSpacing: 0.10)
                    activePaywall = nil
                    analytics?.track(
                        AnalyticsFunnels.adRewardGranted(
                            placement: "continue",
                            rewardType: "continue",
                            amount: 1
                        )
                    )
                } else {
                    monetizationToast = "Could not continue this board."
                }
            }
        }
    }

    func claimGameOverCoinsWithAd() {
        guard canClaimGameOverCoinsWithAd else { return }

        Task {
            let grant = await rewardedAds.showAdAndReward(for: .bonusCoins) {
                self.meta.claimRewardedAd()
            }

            await MainActor.run {
                guard let grant else {
                    monetizationToast = "Rewarded coin ad unavailable."
                    return
                }
                rewardBanner = "+\(grant.coins) coins"
                monetizationToast = "+\(grant.coins) coins earned."
                AudioEngine.shared.play(.reward, minimumSpacing: 0.08)
                analytics?.track(
                    AnalyticsFunnels.adRewardGranted(
                        placement: "game_over_bonus_coins",
                        rewardType: "coins",
                        amount: grant.coins
                    )
                )
            }
        }
    }

    func openGameOverOffer() {
        guard state.runtime == .gameOver else { return }
        guard !meta.removeAdsEnabled else { return }
        activePaywall = makeGameOverPaywallViewModel()
    }

    func dismissRewardBanner() {
        rewardBanner = nil
    }

    func dismissComboBanner() {
        comboBanner = nil
    }

    func dismissObjectiveBanner() {
        objectiveBanner = nil
    }

    func dismissMonetizationToast() {
        monetizationToast = nil
    }

    private func bindDependencies() {
        meta.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        rewardedAds.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func handleGameOverFlow() {
        totalGameOvers += 1
        rewardedAds.warmupIfNeeded()
        latestResultSummary = makeRunSummary()
        trackGameOver()

        Task {
            _ = await interstitialAds.handleGameOver()
            await MainActor.run {
                presentSoftPaywallIfEligible()
            }
        }
    }

    private func presentSoftPaywallIfEligible() {
        guard !meta.removeAdsEnabled else { return }
        let config = remoteConfig.currentMonetizationConfig
        guard config.gameOverPaywall.shouldPresent(totalGameOvers: totalGameOvers) else { return }
        activePaywall = makeGameOverPaywallViewModel()
    }

    private func makeGameOverPaywallViewModel() -> PaywallViewModel {
        let config = remoteConfig.currentMonetizationConfig
        let shouldShowStarterPack = config.gameOverPaywall.showStarterPackUpsell && config.starterPackEnabled && !meta.starterPackPurchased

        return PaywallViewModel(
            placement: .gameOver,
            variant: config.paywallVariant,
            starterPackProduct: shouldShowStarterPack ? Products.starterPack : nil,
            bundleBonusThemeID: config.removeAdsBundleBonusThemeID,
            purchaseManager: purchaseManager,
            analytics: analytics
        ) { [weak self] bundleBonusThemeID in
            guard let self else { return }
            meta.unlockRemoveAds()
            if let bundleBonusThemeID {
                meta.grantTheme(themeID: bundleBonusThemeID, autoEquip: true)
                monetizationToast = "Bundle unlocked: ads removed + bonus theme."
            } else {
                monetizationToast = "Remove Ads unlocked."
            }
        } onStarterPackUnlocked: { [weak self] product in
            guard let self else { return }
            let applied = meta.applyStarterPack(product: product)
            monetizationToast = applied ? "Starter Pack delivered: +\(product.coinGrant) coins." : "Starter Pack already claimed."
        }
    }

    private func refreshAhaCoachmark() {
        showAhaCoachmark = meta.shouldShowAhaCoachmark
        guard showAhaCoachmark else { return }
        analytics?.track(AnalyticsFunnels.tutorialStep(step: "aha_prompt", status: "shown"))
        Task {
            try? await Task.sleep(for: .seconds(30))
            await MainActor.run {
                self.showAhaCoachmark = false
            }
        }
    }

    private func trackGameStart() {
        analytics?.track(AnalyticsFunnels.gameStart(mode: state.mode))
    }

    private func trackGameOver() {
        let elapsed = max(0, Int(Date().timeIntervalSince(runStartedAt).rounded(.down)))
        analytics?.track(
            AnalyticsFunnels.gameOver(
                mode: state.mode,
                score: state.score.total,
                durationSeconds: elapsed,
                clears: runClears,
                comboMax: max(runComboMax, state.score.comboChain)
            )
        )
    }

    private func resetRunTelemetry() {
        runStartedAt = Date()
        runClears = 0
        runComboMax = 1
        didTrackFirstClearTutorial = false
    }

    private func makeRunSummary() -> GameResultSummary {
        GameResultSummary(
            mode: state.mode,
            score: state.score.total,
            turn: state.turn,
            clears: runClears,
            comboMax: max(runComboMax, state.score.comboChain),
            durationSeconds: max(0, Int(Date().timeIntervalSince(runStartedAt).rounded(.down))),
            rewardedContinues: rewardedContinuesUsedThisRun
        )
    }

    private func comboBannerText(multiplier: Int, chain: Int) -> String {
        switch multiplier {
        case 4...:
            return "Inferno Combo x\(multiplier) • Chain \(chain)"
        case 3:
            return "Mega Combo x\(multiplier) • Chain \(chain)"
        default:
            return "Combo x\(multiplier) • Chain \(chain)"
        }
    }

    private func advanceObjective(previousState: GameState, currentState: GameState, events: [GameEvent]) {
        guard var objective = objectiveRuntime else { return }

        let linesCleared = events.reduce(into: 0) { partial, event in
            if case let .linesCleared(count) = event {
                partial += count
            }
        }
        let scoreDelta = max(0, currentState.score.total - previousState.score.total)
        let piecePlaced = events.contains(where: {
            if case .piecePlaced = $0 { return true }
            return false
        })

        switch objective.type {
        case .clearLines:
            objective.progress += linesCleared
        case .placePieces:
            objective.progress += piecePlaced ? 1 : 0
        case .comboChain:
            objective.progress = max(objective.progress, currentState.score.comboChain)
        case .scoreSprint:
            objective.progress += scoreDelta
        }

        objective.progress = min(objective.progress, objective.target)
        objectiveRuntime = objective
        activeObjective = objective.toDisplay()

        guard objective.progress >= objective.target else { return }

        if objective.rewardCoins > 0 {
            meta.grantCoins(objective.rewardCoins)
            rewardBanner = "+\(objective.rewardCoins) coins"
        }

        objectiveBanner = "Mission Complete: \(objective.title)"
        AudioEngine.shared.play(.objective, minimumSpacing: 0.20)
        HapticManager.shared.bigCombo()
        objectiveCompletions += 1
        objectiveTier = min(20, objectiveTier + (objectiveCompletions % 2 == 0 ? 1 : 0))
        generateNextObjective(resetProgression: false)
    }

    private func generateNextObjective(resetProgression: Bool) {
        if resetProgression {
            objectiveTier = 1
            objectiveCompletions = 0
        }

        let type = RuntimeObjective.ObjectiveType.cycle[objectiveCompletions % RuntimeObjective.ObjectiveType.cycle.count]
        let objective = RuntimeObjective.make(type: type, tier: objectiveTier)
        objectiveRuntime = objective
        activeObjective = objective.toDisplay()
    }
}

private struct RuntimeObjective: Equatable {
    enum ObjectiveType: CaseIterable {
        case clearLines
        case placePieces
        case comboChain
        case scoreSprint

        static let cycle: [ObjectiveType] = [.clearLines, .placePieces, .comboChain, .scoreSprint]
    }

    let type: ObjectiveType
    let title: String
    let subtitle: String
    let target: Int
    let rewardCoins: Int
    var progress: Int

    static func make(type: ObjectiveType, tier: Int) -> RuntimeObjective {
        switch type {
        case .clearLines:
            let target = min(12, 3 + (tier / 2))
            return RuntimeObjective(
                type: .clearLines,
                title: "Line Runner",
                subtitle: "Clear \(target) lines this run",
                target: target,
                rewardCoins: 20 + (tier * 5),
                progress: 0
            )
        case .placePieces:
            let target = min(28, 7 + tier)
            return RuntimeObjective(
                type: .placePieces,
                title: "Builder Flow",
                subtitle: "Place \(target) pieces cleanly",
                target: target,
                rewardCoins: 18 + (tier * 4),
                progress: 0
            )
        case .comboChain:
            let target = min(7, 2 + (tier / 3))
            return RuntimeObjective(
                type: .comboChain,
                title: "Combo Artist",
                subtitle: "Reach combo chain \(target)",
                target: target,
                rewardCoins: 28 + (tier * 6),
                progress: 0
            )
        case .scoreSprint:
            let target = 300 + (tier * 110)
            return RuntimeObjective(
                type: .scoreSprint,
                title: "Score Sprint",
                subtitle: "Earn \(target) score in mission",
                target: target,
                rewardCoins: 24 + (tier * 5),
                progress: 0
            )
        }
    }

    func toDisplay() -> GameViewModel.LiveObjective {
        GameViewModel.LiveObjective(
            title: title,
            subtitle: subtitle,
            progress: progress,
            target: target,
            rewardCoins: rewardCoins
        )
    }
}
