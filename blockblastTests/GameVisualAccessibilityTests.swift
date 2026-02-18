import SpriteKit
import Testing
@testable import blockblast

struct GameVisualAccessibilityTests {
    @Test func highContrastThemeOverridesDefaults() {
        let standard = GameVisualTheme.from(blockTheme: nil, gridTheme: nil, highContrast: false)
        let highContrast = GameVisualTheme.from(blockTheme: nil, gridTheme: nil, highContrast: true)

        #expect(standard.highContrastMode == false)
        #expect(highContrast.highContrastMode == true)
        #expect(colorComponents(standard.boardBackground) != colorComponents(highContrast.boardBackground))
        #expect(colorComponents(standard.emptyCell) != colorComponents(highContrast.emptyCell))
    }

    @Test func highContrastPaletteIsAvailableForAllPieces() {
        let theme = GameVisualTheme.from(blockTheme: nil, gridTheme: nil, highContrast: true)

        for kind in Piece.Kind.allCases {
            #expect(theme.piecePalette(for: kind).count == 3)
        }
    }
}

private func colorComponents(_ color: SKColor) -> [CGFloat] {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue, alpha]
}
