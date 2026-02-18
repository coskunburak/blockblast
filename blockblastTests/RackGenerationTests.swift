import Testing
@testable import blockblast

struct RackGenerationTests {
    @Test func generatedRackKeepsVarietyAcrossKindsAndFootprints() {
        var bag = PieceBag(seed: 2026)
        let grid = Grid(size: 8)

        let rack = bag.drawRack(
            slotCount: DifficultyTuning.classicDefault.pieceSlots,
            tuning: .classicDefault,
            on: grid
        )

        #expect(rack.count == DifficultyTuning.classicDefault.pieceSlots)
        #expect(Set(rack.map(\.kind)).count >= 2)
        #expect(Set(rack.map { $0.blocks.count }).count >= 2)
    }

    @Test func generatedRackOffersPlayableSupportOnTightBoard() {
        var grid = Grid(size: 8)
        let lockedCells = (0..<8).flatMap { row in
            (0..<8).compactMap { column -> Cell? in
                if row >= 6 && column >= 6 { return nil }
                return Cell(row: row, column: column)
            }
        }
        grid.fill(lockedCells)

        var bag = PieceBag(seed: 9042)
        let rack = bag.drawRack(
            slotCount: DifficultyTuning.classicDefault.pieceSlots,
            tuning: .classicDefault,
            on: grid
        )

        let hasLegalMove = rack.contains { piece in
            PlacementRules.hasAnyValidPlacement(piece: piece, on: grid)
        }
        let containsSupportShape = rack.contains { piece in
            switch piece.kind {
            case .dot1, .line3, .square2, .l3, .o4:
                return true
            default:
                return false
            }
        }

        #expect(hasLegalMove)
        #expect(containsSupportShape)
    }
}
