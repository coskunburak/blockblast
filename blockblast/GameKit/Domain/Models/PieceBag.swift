import Foundation

struct PieceBag: Codable, Equatable {
    private(set) var queue: [Piece.Kind]
    private(set) var state: UInt64
    private(set) var drawsWithoutDot: Int
    private(set) var previousKind: Piece.Kind?
    private(set) var previousKindStreak: Int

    init(seed: UInt64) {
        self.queue = []
        self.state = seed
        self.drawsWithoutDot = 0
        self.previousKind = nil
        self.previousKindStreak = 0
    }

    mutating func draw(tuning: DifficultyTuning) -> Piece {
        if queue.isEmpty {
            refillBag(tuning: tuning)
        }

        applyDotFairness(tuning: tuning)
        applyRunLengthFairness()

        let kind = queue.removeFirst()
        updateDrawStats(for: kind)
        return Piece.make(kind: kind)
    }

    mutating func drawRack(slotCount: Int, tuning: DifficultyTuning, on grid: Grid) -> [Piece] {
        let resolvedSlotCount = max(0, slotCount)
        guard resolvedSlotCount > 0 else { return [] }

        let poolCount = max(resolvedSlotCount, min(resolvedSlotCount * 3, resolvedSlotCount + 8))
        var pool: [Piece] = []
        pool.reserveCapacity(poolCount)

        for _ in 0..<poolCount {
            pool.append(draw(tuning: tuning))
        }

        let candidates = rackCombinations(from: pool, taking: resolvedSlotCount)
        guard !candidates.isEmpty else {
            return Array(pool.prefix(resolvedSlotCount))
        }

        let pressure = boardPressure(on: grid)
        var insightCache: [Piece.Kind: PlacementInsight] = [:]
        var bestRack = candidates[0]
        var bestScore = rackScore(
            for: bestRack,
            on: grid,
            pressure: pressure,
            insightCache: &insightCache
        )
        var bestSignature = rackSignature(bestRack)
        var bestDiverseRack: [Piece]? = rackHasStrongDiversity(bestRack) ? bestRack : nil
        var bestDiverseScore = bestScore
        var bestDiverseSignature = bestSignature

        for candidate in candidates.dropFirst() {
            let score = rackScore(
                for: candidate,
                on: grid,
                pressure: pressure,
                insightCache: &insightCache
            )
            let signature = rackSignature(candidate)
            if score > bestScore || (score == bestScore && signature < bestSignature) {
                bestRack = candidate
                bestScore = score
                bestSignature = signature
            }

            if rackHasStrongDiversity(candidate),
               bestDiverseRack == nil || score > bestDiverseScore || (score == bestDiverseScore && signature < bestDiverseSignature) {
                bestDiverseRack = candidate
                bestDiverseScore = score
                bestDiverseSignature = signature
            }
        }

        let resolvedRack = bestDiverseRack ?? bestRack
        return injectSupportPieceIfNeeded(
            into: resolvedRack,
            tuning: tuning,
            on: grid,
            pressure: pressure,
            insightCache: &insightCache
        )
    }

    private mutating func updateDrawStats(for kind: Piece.Kind) {
        if kind == .dot1 {
            drawsWithoutDot = 0
        } else {
            drawsWithoutDot += 1
        }

        if previousKind == kind {
            previousKindStreak += 1
        } else {
            previousKind = kind
            previousKindStreak = 1
        }
    }

    private mutating func applyDotFairness(tuning: DifficultyTuning) {
        guard drawsWithoutDot >= tuning.maxDot1Drought else { return }

        // Guarantee the next draw yields `dot1` once drought limit is reached.
        if queue.first != .dot1 {
            queue.insert(.dot1, at: 0)
        }
    }

    private mutating func applyRunLengthFairness() {
        guard let previousKind, previousKindStreak >= 2 else { return }

        if queue.first == previousKind,
           let candidateIndex = queue.firstIndex(where: { $0 != previousKind }) {
            queue.swapAt(0, candidateIndex)
        }
    }

    private mutating func refillBag(tuning: DifficultyTuning) {
        let drawCount = Piece.Kind.allCases.count
        var drawnKinds: [Piece.Kind] = []
        drawnKinds.reserveCapacity(drawCount)

        for _ in 0..<drawCount {
            drawnKinds.append(weightedKind(from: tuning.pieceWeights))
        }

        // Keeps order less predictable even if weighted draw repeats a subset.
        for index in drawnKinds.indices.dropLast() {
            let swapIndex = Int(nextRandom() % UInt64(drawnKinds.count - index)) + index
            drawnKinds.swapAt(index, swapIndex)
        }

        queue.append(contentsOf: drawnKinds)
    }

    private func rackCombinations(from pool: [Piece], taking count: Int) -> [[Piece]] {
        guard count > 0, pool.count >= count else { return [] }

        var results: [[Piece]] = []
        var current: [Piece] = []
        current.reserveCapacity(count)

        func backtrack(start: Int) {
            if current.count == count {
                results.append(current)
                return
            }

            let remaining = count - current.count
            guard start <= pool.count - remaining else { return }

            for index in start...(pool.count - remaining) {
                current.append(pool[index])
                backtrack(start: index + 1)
                _ = current.popLast()
            }
        }

        backtrack(start: 0)
        return results
    }

    private func rackScore(
        for rack: [Piece],
        on grid: Grid,
        pressure: Double,
        insightCache: inout [Piece.Kind: PlacementInsight]
    ) -> Int {
        guard !rack.isEmpty else { return Int.min / 4 }

        let uniqueKinds = Set(rack.map(\.kind)).count
        let uniqueFamilies = Set(rack.map { family(for: $0.kind) }).count
        let uniqueFootprints = Set(rack.map { $0.blocks.count }).count
        let duplicates = rack.count - uniqueKinds

        var score = (uniqueKinds * 180) + (uniqueFamilies * 140) + (uniqueFootprints * 110)
        score -= duplicates * 160

        if uniqueFamilies == 1 {
            score -= 180
        }
        if uniqueFootprints == 1 {
            score -= 120
        }

        var totalLegal = 0
        var maxLegal = 0
        var helperCoverage = 0

        for piece in rack {
            let insight = cachedPlacementInsight(for: piece, on: grid, cache: &insightCache)
            totalLegal += insight.legalCount
            maxLegal = max(maxLegal, insight.legalCount)

            score += min(insight.legalCount, 16) * 18
            score += insight.bestClearLines * 320

            if isHelperKind(piece.kind), insight.legalCount > 0 {
                helperCoverage += 1
                score += Int((Double(insight.legalCount) * (24 + (18 * pressure))).rounded())
            }
        }

        if maxLegal == 0 {
            score -= 4_000
        } else if totalLegal <= rack.count {
            score -= 280
        } else {
            score += min(totalLegal, 24) * 8
        }

        if pressure > 0.35 {
            score += Int((Double(maxLegal) * (38 * pressure)).rounded())
            if helperCoverage == 0 {
                score -= 260
            }
        }

        return score
    }

    private mutating func injectSupportPieceIfNeeded(
        into rack: [Piece],
        tuning: DifficultyTuning,
        on grid: Grid,
        pressure: Double,
        insightCache: inout [Piece.Kind: PlacementInsight]
    ) -> [Piece] {
        guard !rack.isEmpty else { return rack }
        guard pressure > 0.15 else { return rack }

        let bestLegalInRack = rack.map {
            cachedPlacementInsight(for: $0, on: grid, cache: &insightCache).legalCount
        }.max() ?? 0
        let minimumComfort = pressure > 0.55 ? 4 : 3
        guard bestLegalInRack < minimumComfort else { return rack }

        var candidatePiece: Piece?
        var candidateScore = Int.min

        for _ in 0..<14 {
            let drawn = draw(tuning: tuning)
            let score = supportScore(
                for: drawn,
                on: grid,
                pressure: pressure,
                insightCache: &insightCache
            )
            if score > candidateScore {
                candidatePiece = drawn
                candidateScore = score
            }
        }

        guard let candidatePiece else { return rack }
        let candidateInsight = placementInsight(for: candidatePiece, on: grid)
        guard candidateInsight.legalCount > 0 else { return rack }

        var weakestIndex = 0
        var weakestScore = Int.max

        for (index, piece) in rack.enumerated() {
            let score = supportScore(
                for: piece,
                on: grid,
                pressure: pressure,
                insightCache: &insightCache
            )
            if score < weakestScore {
                weakestScore = score
                weakestIndex = index
            }
        }

        guard candidateScore > weakestScore else { return rack }

        let originalFootprints = Set(rack.map { $0.blocks.count }).count
        let originalFamilies = Set(rack.map { family(for: $0.kind) }).count
        if originalFootprints >= 2 {
            var trialRack = rack
            trialRack[weakestIndex] = candidatePiece
            let trialFootprints = Set(trialRack.map { $0.blocks.count }).count
            guard trialFootprints >= 2 else { return rack }
            if originalFamilies >= 2 {
                let trialFamilies = Set(trialRack.map { family(for: $0.kind) }).count
                guard trialFamilies >= 2 else { return rack }
            }
        }

        var resolved = rack
        resolved[weakestIndex] = candidatePiece
        return resolved
    }

    private func supportScore(
        for piece: Piece,
        on grid: Grid,
        pressure: Double,
        insightCache: inout [Piece.Kind: PlacementInsight]
    ) -> Int {
        let insight = cachedPlacementInsight(for: piece, on: grid, cache: &insightCache)
        let helperBias = isHelperKind(piece.kind) ? 120 : 0
        return (insight.legalCount * 42) +
            (insight.bestClearLines * 350) +
            Int((Double(helperBias) * (0.8 + pressure)).rounded())
    }

    private func cachedPlacementInsight(
        for piece: Piece,
        on grid: Grid,
        cache: inout [Piece.Kind: PlacementInsight]
    ) -> PlacementInsight {
        if let cached = cache[piece.kind] {
            return cached
        }
        let insight = placementInsight(for: piece, on: grid)
        cache[piece.kind] = insight
        return insight
    }

    private func placementInsight(for piece: Piece, on grid: Grid) -> PlacementInsight {
        guard grid.size > 0 else { return PlacementInsight(legalCount: 0, bestClearLines: 0) }

        var rowCounts = Array(repeating: 0, count: grid.size)
        var columnCounts = Array(repeating: 0, count: grid.size)
        for cell in grid.filled {
            rowCounts[cell.row] += 1
            columnCounts[cell.column] += 1
        }

        var legalCount = 0
        var bestClearLines = 0
        var translated: [Cell] = []
        translated.reserveCapacity(piece.blocks.count)

        var rowDeltas = Array(repeating: 0, count: grid.size)
        var columnDeltas = Array(repeating: 0, count: grid.size)
        var touchedRows: [Int] = []
        touchedRows.reserveCapacity(piece.blocks.count)
        var touchedColumns: [Int] = []
        touchedColumns.reserveCapacity(piece.blocks.count)

        for row in 0..<grid.size {
            for column in 0..<grid.size {
                translated.removeAll(keepingCapacity: true)
                touchedRows.removeAll(keepingCapacity: true)
                touchedColumns.removeAll(keepingCapacity: true)
                var isLegal = true

                for block in piece.blocks {
                    let cell = Cell(row: row + block.row, column: column + block.column)
                    if !grid.isInside(cell) || grid.contains(cell) {
                        isLegal = false
                        break
                    }

                    translated.append(cell)
                    if rowDeltas[cell.row] == 0 {
                        touchedRows.append(cell.row)
                    }
                    rowDeltas[cell.row] += 1

                    if columnDeltas[cell.column] == 0 {
                        touchedColumns.append(cell.column)
                    }
                    columnDeltas[cell.column] += 1
                }

                guard isLegal else {
                    for rowIndex in touchedRows {
                        rowDeltas[rowIndex] = 0
                    }
                    for columnIndex in touchedColumns {
                        columnDeltas[columnIndex] = 0
                    }
                    continue
                }

                legalCount += 1

                var clearLines = 0
                for rowIndex in touchedRows {
                    if rowCounts[rowIndex] + rowDeltas[rowIndex] == grid.size {
                        clearLines += 1
                    }
                    rowDeltas[rowIndex] = 0
                }
                for columnIndex in touchedColumns {
                    if columnCounts[columnIndex] + columnDeltas[columnIndex] == grid.size {
                        clearLines += 1
                    }
                    columnDeltas[columnIndex] = 0
                }

                bestClearLines = max(bestClearLines, clearLines)
            }
        }

        return PlacementInsight(legalCount: legalCount, bestClearLines: bestClearLines)
    }

    private func boardPressure(on grid: Grid) -> Double {
        let totalCells = max(1, grid.size * grid.size)
        let fillRatio = Double(grid.filled.count) / Double(totalCells)
        return max(0, min(1, (fillRatio - 0.36) / 0.52))
    }

    private func rackHasStrongDiversity(_ rack: [Piece]) -> Bool {
        Set(rack.map { family(for: $0.kind) }).count >= 2 &&
            Set(rack.map { $0.blocks.count }).count >= 2
    }

    private func family(for kind: Piece.Kind) -> KindFamily {
        switch kind {
        case .i4, .i5, .line3:
            return .line
        case .o4, .square2, .p5:
            return .square
        case .t4, .plus5:
            return .tee
        case .l4, .j4, .l3, .u5, .v5:
            return .corner
        case .s4, .z4, .w5, .n5:
            return .zigzag
        case .dot1:
            return .single
        }
    }

    private func isHelperKind(_ kind: Piece.Kind) -> Bool {
        switch kind {
        case .dot1, .line3, .square2, .l3:
            return true
        default:
            return false
        }
    }

    private func rackSignature(_ rack: [Piece]) -> String {
        rack.map { $0.kind.rawValue }.joined(separator: "|")
    }

    private mutating func weightedKind(from weights: PieceWeightTuning) -> Piece.Kind {
        let kinds = Piece.Kind.allCases
        let totalWeight = kinds.reduce(into: 0) { partial, kind in
            partial += max(0, weights.weight(for: kind))
        }

        guard totalWeight > 0 else {
            return kinds[Int(nextRandom() % UInt64(kinds.count))]
        }

        var bucket = Int(nextRandom() % UInt64(totalWeight))
        for kind in kinds {
            bucket -= max(0, weights.weight(for: kind))
            if bucket < 0 {
                return kind
            }
        }

        return .dot1
    }

    private mutating func nextRandom() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}

private enum KindFamily: Int, Hashable {
    case line
    case square
    case tee
    case corner
    case zigzag
    case single
}

private struct PlacementInsight {
    let legalCount: Int
    let bestClearLines: Int
}
