import Foundation

struct Piece: Identifiable, Hashable, Codable {
    typealias ID = UUID

    enum Kind: String, CaseIterable, Codable {
        // Tetromino-like shapes
        case i4
        case i5
        case o4
        case t4
        case l4
        case j4
        case s4
        case z4

        // Block-blast friendly extras
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

    let id: ID
    let kind: Kind
    let blocks: [Cell]

    init(id: ID = UUID(), kind: Kind, blocks: [Cell]) {
        self.id = id
        self.kind = kind
        self.blocks = blocks
    }

    static func make(kind: Kind) -> Piece {
        Piece(kind: kind, blocks: shapeBlocks(kind))
    }

    private static func shapeBlocks(_ kind: Kind) -> [Cell] {
        switch kind {
        case .i4:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 0, column: 2), Cell(row: 0, column: 3)]
        case .i5:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 0, column: 2), Cell(row: 0, column: 3), Cell(row: 0, column: 4)]
        case .o4:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 1, column: 0), Cell(row: 1, column: 1)]
        case .t4:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 0, column: 2), Cell(row: 1, column: 1)]
        case .l4:
            return [Cell(row: 0, column: 0), Cell(row: 1, column: 0), Cell(row: 2, column: 0), Cell(row: 2, column: 1)]
        case .j4:
            return [Cell(row: 0, column: 1), Cell(row: 1, column: 1), Cell(row: 2, column: 1), Cell(row: 2, column: 0)]
        case .s4:
            return [Cell(row: 0, column: 1), Cell(row: 0, column: 2), Cell(row: 1, column: 0), Cell(row: 1, column: 1)]
        case .z4:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 1, column: 1), Cell(row: 1, column: 2)]
        case .plus5:
            return [Cell(row: 0, column: 1), Cell(row: 1, column: 0), Cell(row: 1, column: 1), Cell(row: 1, column: 2), Cell(row: 2, column: 1)]
        case .u5:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 2), Cell(row: 1, column: 0), Cell(row: 1, column: 1), Cell(row: 1, column: 2)]
        case .p5:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 1, column: 0), Cell(row: 1, column: 1), Cell(row: 2, column: 0)]
        case .v5:
            return [Cell(row: 0, column: 0), Cell(row: 1, column: 0), Cell(row: 2, column: 0), Cell(row: 2, column: 1), Cell(row: 2, column: 2)]
        case .w5:
            return [Cell(row: 0, column: 0), Cell(row: 1, column: 0), Cell(row: 1, column: 1), Cell(row: 2, column: 1), Cell(row: 2, column: 2)]
        case .n5:
            return [Cell(row: 0, column: 1), Cell(row: 0, column: 2), Cell(row: 1, column: 0), Cell(row: 1, column: 1), Cell(row: 2, column: 0)]
        case .line3:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 0, column: 2)]
        case .square2:
            return [Cell(row: 0, column: 0), Cell(row: 0, column: 1), Cell(row: 1, column: 0), Cell(row: 1, column: 1)]
        case .l3:
            return [Cell(row: 0, column: 0), Cell(row: 1, column: 0), Cell(row: 1, column: 1)]
        case .dot1:
            return [Cell(row: 0, column: 0)]
        }
    }
}
