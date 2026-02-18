import Testing
@testable import blockblast

struct PlacementRulesTests {
    @Test func placementRejectsOutOfBoundsAnchor() {
        let grid = Grid(size: 8)
        let piece = Piece.make(kind: .i4)

        #expect(PlacementRules.canPlace(piece: piece, at: Cell(row: 7, column: 7), on: grid) == false)
    }

    @Test func placementRejectsOverlap() {
        var grid = Grid(size: 8)
        grid.fill([Cell(row: 0, column: 0)])
        let piece = Piece.make(kind: .dot1)

        #expect(PlacementRules.canPlace(piece: piece, at: Cell(row: 0, column: 0), on: grid) == false)
    }

    @Test func placementAcceptsValidAnchor() {
        let grid = Grid(size: 8)
        let piece = Piece.make(kind: .l3)

        #expect(PlacementRules.canPlace(piece: piece, at: Cell(row: 5, column: 5), on: grid) == true)
    }
}
