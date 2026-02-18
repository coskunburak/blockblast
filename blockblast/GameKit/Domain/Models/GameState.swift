import Foundation

enum GameMode: String, Codable {
    case classic
    case dailyChallenge
}

enum RuntimeState: Codable, Equatable {
    case running
    case paused
    case gameOver
}

struct GameState: Codable, Equatable {
    var mode: GameMode
    var runtime: RuntimeState
    var grid: Grid
    var upcomingPieces: [Piece]
    var bag: PieceBag
    var score: ScoreState
    var tuning: DifficultyTuning
    var turn: Int
    var lastMove: Move?
    var comboTracker: ComboTracker
    var powerUpInventory: PowerUpInventory
    var interactionState: GameInteractionState
    var nextSpawnIsWildcard: Bool

    private enum CodingKeys: String, CodingKey {
        case mode
        case runtime
        case grid
        case upcomingPieces
        case bag
        case score
        case tuning
        case turn
        case lastMove
        case comboTracker
        case powerUpInventory
        case interactionState
        case nextSpawnIsWildcard
    }

    init(
        mode: GameMode,
        runtime: RuntimeState,
        grid: Grid,
        upcomingPieces: [Piece],
        bag: PieceBag,
        score: ScoreState,
        tuning: DifficultyTuning,
        turn: Int,
        lastMove: Move?,
        comboTracker: ComboTracker = ComboTracker(),
        powerUpInventory: PowerUpInventory = PowerUpInventory(),
        interactionState: GameInteractionState = GameInteractionState(),
        nextSpawnIsWildcard: Bool = false
    ) {
        self.mode = mode
        self.runtime = runtime
        self.grid = grid
        self.upcomingPieces = upcomingPieces
        self.bag = bag
        self.score = score
        self.tuning = tuning
        self.turn = turn
        self.lastMove = lastMove
        self.comboTracker = comboTracker
        self.powerUpInventory = powerUpInventory
        self.interactionState = interactionState
        self.nextSpawnIsWildcard = nextSpawnIsWildcard
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(GameMode.self, forKey: .mode)
        runtime = try container.decode(RuntimeState.self, forKey: .runtime)
        grid = try container.decode(Grid.self, forKey: .grid)
        upcomingPieces = try container.decode([Piece].self, forKey: .upcomingPieces)
        bag = try container.decode(PieceBag.self, forKey: .bag)
        score = try container.decode(ScoreState.self, forKey: .score)
        tuning = try container.decode(DifficultyTuning.self, forKey: .tuning)
        turn = try container.decode(Int.self, forKey: .turn)
        lastMove = try container.decodeIfPresent(Move.self, forKey: .lastMove)
        comboTracker = try container.decodeIfPresent(ComboTracker.self, forKey: .comboTracker) ??
            ComboTracker(currentCombo: score.comboChain)
        powerUpInventory = try container.decodeIfPresent(PowerUpInventory.self, forKey: .powerUpInventory) ??
            PowerUpInventory()
        interactionState = try container.decodeIfPresent(GameInteractionState.self, forKey: .interactionState) ??
            GameInteractionState()
        nextSpawnIsWildcard = try container.decodeIfPresent(Bool.self, forKey: .nextSpawnIsWildcard) ??
            false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(grid, forKey: .grid)
        try container.encode(upcomingPieces, forKey: .upcomingPieces)
        try container.encode(bag, forKey: .bag)
        try container.encode(score, forKey: .score)
        try container.encode(tuning, forKey: .tuning)
        try container.encode(turn, forKey: .turn)
        try container.encodeIfPresent(lastMove, forKey: .lastMove)
        try container.encode(comboTracker, forKey: .comboTracker)
        try container.encode(powerUpInventory, forKey: .powerUpInventory)
        try container.encode(interactionState, forKey: .interactionState)
        try container.encode(nextSpawnIsWildcard, forKey: .nextSpawnIsWildcard)
    }

    static func initial(
        mode: GameMode,
        gridSize: Int,
        seed: UInt64,
        tuning: DifficultyTuning
    ) -> GameState {
        var bag = PieceBag(seed: seed)
        let grid = Grid(size: gridSize)
        let pieces = bag.drawRack(slotCount: tuning.pieceSlots, tuning: tuning, on: grid)

        return GameState(
            mode: mode,
            runtime: .running,
            grid: grid,
            upcomingPieces: pieces,
            bag: bag,
            score: ScoreState(),
            tuning: tuning,
            turn: 0,
            lastMove: nil,
            comboTracker: ComboTracker(),
            powerUpInventory: PowerUpInventory(),
            interactionState: GameInteractionState(),
            nextSpawnIsWildcard: false
        )
    }

    var isPowerUpModeActive: Bool {
        interactionState.isPowerUpActive
    }

    var selectedPowerUpType: PowerUpType? {
        interactionState.selectedPowerUp.asPowerUpType
    }

    var validTargetPositions: Set<Cell> {
        guard isPowerUpModeActive else { return [] }

        switch interactionState.selectedPowerUp {
        case .none, .rainbow:
            return []
        case .hammer:
            return grid.filled
        case .bomb:
            var targets: Set<Cell> = []
            for row in 0..<grid.size {
                for column in 0..<grid.size {
                    targets.insert(Cell(row: row, column: column))
                }
            }
            return targets
        }
    }
}
