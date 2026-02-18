import Testing
@testable import blockblast

struct PieceCatalogTests {
    @Test func newAdvancedShapesArePresentAndPlayable() {
        let advancedKinds: [Piece.Kind] = [.i5, .plus5, .u5, .p5, .v5, .w5, .n5]
        for kind in advancedKinds {
            let piece = Piece.make(kind: kind)
            #expect(piece.blocks.count == 5)
        }
    }

    @Test func allShapesUseNormalizedPositiveCoordinates() {
        for kind in Piece.Kind.allCases {
            let piece = Piece.make(kind: kind)
            let minRow = piece.blocks.map(\.row).min() ?? 0
            let minColumn = piece.blocks.map(\.column).min() ?? 0
            #expect(minRow >= 0)
            #expect(minColumn >= 0)
        }
    }
}
