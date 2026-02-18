import Foundation

struct PieceWeightTuning: Codable, Equatable {
    var i4: Int
    var i5: Int
    var o4: Int
    var t4: Int
    var l4: Int
    var j4: Int
    var s4: Int
    var z4: Int
    var plus5: Int
    var u5: Int
    var p5: Int
    var v5: Int
    var w5: Int
    var n5: Int
    var line3: Int
    var square2: Int
    var l3: Int
    var dot1: Int

    init(
        i4: Int = 100,
        i5: Int = 72,
        o4: Int = 100,
        t4: Int = 100,
        l4: Int = 100,
        j4: Int = 100,
        s4: Int = 100,
        z4: Int = 100,
        plus5: Int = 68,
        u5: Int = 76,
        p5: Int = 74,
        v5: Int = 70,
        w5: Int = 74,
        n5: Int = 72,
        line3: Int = 100,
        square2: Int = 100,
        l3: Int = 100,
        dot1: Int = 100
    ) {
        self.i4 = i4
        self.i5 = i5
        self.o4 = o4
        self.t4 = t4
        self.l4 = l4
        self.j4 = j4
        self.s4 = s4
        self.z4 = z4
        self.plus5 = plus5
        self.u5 = u5
        self.p5 = p5
        self.v5 = v5
        self.w5 = w5
        self.n5 = n5
        self.line3 = line3
        self.square2 = square2
        self.l3 = l3
        self.dot1 = dot1
    }

    static let uniform = PieceWeightTuning()

    static let comboFriendly = PieceWeightTuning(
        i4: 125,
        i5: 88,
        o4: 130,
        t4: 105,
        l4: 90,
        j4: 90,
        s4: 85,
        z4: 85,
        plus5: 66,
        u5: 74,
        p5: 80,
        v5: 72,
        w5: 68,
        n5: 70,
        line3: 145,
        square2: 140,
        l3: 110,
        dot1: 95
    )

    static let precision = PieceWeightTuning(
        i4: 95,
        i5: 72,
        o4: 90,
        t4: 125,
        l4: 115,
        j4: 115,
        s4: 110,
        z4: 110,
        plus5: 86,
        u5: 108,
        p5: 112,
        v5: 104,
        w5: 98,
        n5: 100,
        line3: 80,
        square2: 85,
        l3: 120,
        dot1: 105
    )

    private enum CodingKeys: String, CodingKey {
        case i4
        case i5
        case o4
        case t4
        case l4
        case j4
        case s4
        case z4
        case plus5
        case u5
        case p5
        case v5
        case w5
        case n5
        case line3
        case square2
        case l3
        case dot1
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        i4 = try container.decodeIfPresent(Int.self, forKey: .i4) ?? 100
        i5 = try container.decodeIfPresent(Int.self, forKey: .i5) ?? 72
        o4 = try container.decodeIfPresent(Int.self, forKey: .o4) ?? 100
        t4 = try container.decodeIfPresent(Int.self, forKey: .t4) ?? 100
        l4 = try container.decodeIfPresent(Int.self, forKey: .l4) ?? 100
        j4 = try container.decodeIfPresent(Int.self, forKey: .j4) ?? 100
        s4 = try container.decodeIfPresent(Int.self, forKey: .s4) ?? 100
        z4 = try container.decodeIfPresent(Int.self, forKey: .z4) ?? 100
        plus5 = try container.decodeIfPresent(Int.self, forKey: .plus5) ?? 68
        u5 = try container.decodeIfPresent(Int.self, forKey: .u5) ?? 76
        p5 = try container.decodeIfPresent(Int.self, forKey: .p5) ?? 74
        v5 = try container.decodeIfPresent(Int.self, forKey: .v5) ?? 70
        w5 = try container.decodeIfPresent(Int.self, forKey: .w5) ?? 74
        n5 = try container.decodeIfPresent(Int.self, forKey: .n5) ?? 72
        line3 = try container.decodeIfPresent(Int.self, forKey: .line3) ?? 100
        square2 = try container.decodeIfPresent(Int.self, forKey: .square2) ?? 100
        l3 = try container.decodeIfPresent(Int.self, forKey: .l3) ?? 100
        dot1 = try container.decodeIfPresent(Int.self, forKey: .dot1) ?? 100
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(i4, forKey: .i4)
        try container.encode(i5, forKey: .i5)
        try container.encode(o4, forKey: .o4)
        try container.encode(t4, forKey: .t4)
        try container.encode(l4, forKey: .l4)
        try container.encode(j4, forKey: .j4)
        try container.encode(s4, forKey: .s4)
        try container.encode(z4, forKey: .z4)
        try container.encode(plus5, forKey: .plus5)
        try container.encode(u5, forKey: .u5)
        try container.encode(p5, forKey: .p5)
        try container.encode(v5, forKey: .v5)
        try container.encode(w5, forKey: .w5)
        try container.encode(n5, forKey: .n5)
        try container.encode(line3, forKey: .line3)
        try container.encode(square2, forKey: .square2)
        try container.encode(l3, forKey: .l3)
        try container.encode(dot1, forKey: .dot1)
    }

    func weight(for kind: Piece.Kind) -> Int {
        switch kind {
        case .i4:
            return i4
        case .i5:
            return i5
        case .o4:
            return o4
        case .t4:
            return t4
        case .l4:
            return l4
        case .j4:
            return j4
        case .s4:
            return s4
        case .z4:
            return z4
        case .plus5:
            return plus5
        case .u5:
            return u5
        case .p5:
            return p5
        case .v5:
            return v5
        case .w5:
            return w5
        case .n5:
            return n5
        case .line3:
            return line3
        case .square2:
            return square2
        case .l3:
            return l3
        case .dot1:
            return dot1
        }
    }
}

struct DifficultyTuning: Codable, Equatable {
    var pieceSlots: Int
    var maxDot1Drought: Int
    var pieceWeights: PieceWeightTuning
    var baseCellPoint: Int
    var baseLinePoint: Int
    var multiLineBonusStep: Int
    var comboBonusStep: Int
    var streakBonusStep: Int
    var streakStartsAt: Int

    init(
        pieceSlots: Int,
        maxDot1Drought: Int,
        pieceWeights: PieceWeightTuning = .uniform,
        baseCellPoint: Int,
        baseLinePoint: Int,
        multiLineBonusStep: Int,
        comboBonusStep: Int,
        streakBonusStep: Int,
        streakStartsAt: Int
    ) {
        self.pieceSlots = pieceSlots
        self.maxDot1Drought = maxDot1Drought
        self.pieceWeights = pieceWeights
        self.baseCellPoint = baseCellPoint
        self.baseLinePoint = baseLinePoint
        self.multiLineBonusStep = multiLineBonusStep
        self.comboBonusStep = comboBonusStep
        self.streakBonusStep = streakBonusStep
        self.streakStartsAt = streakStartsAt
    }

    static let classicDefault = DifficultyTuning(
        pieceSlots: 3,
        maxDot1Drought: 14,
        pieceWeights: .uniform,
        baseCellPoint: 10,
        baseLinePoint: 50,
        multiLineBonusStep: 80,
        comboBonusStep: 30,
        streakBonusStep: 20,
        streakStartsAt: 3
    )

    static let dailyDefault = DifficultyTuning(
        pieceSlots: 3,
        maxDot1Drought: 10,
        pieceWeights: .uniform,
        baseCellPoint: 10,
        baseLinePoint: 60,
        multiLineBonusStep: 90,
        comboBonusStep: 35,
        streakBonusStep: 25,
        streakStartsAt: 2
    )

    static func forMode(_ mode: GameMode, remoteOverride: DifficultyTuning? = nil) -> DifficultyTuning {
        if let remoteOverride {
            return remoteOverride
        }
        switch mode {
        case .classic:
            return .classicDefault
        case .dailyChallenge:
            return .dailyDefault
        }
    }
}
