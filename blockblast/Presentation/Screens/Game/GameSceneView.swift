import SpriteKit
import SwiftUI

struct GameVisualTheme {
    var highContrastMode: Bool
    var boardBackground: SKColor
    var emptyCell: SKColor
    var filledCell: SKColor
    var cellStroke: SKColor
    var validHighlight: SKColor
    var invalidHighlight: SKColor

    var pieceA: SKColor
    var pieceB: SKColor
    var pieceC: SKColor

    static let `default` = GameVisualTheme(
        highContrastMode: false,
        boardBackground: SKColor(red: 0.20, green: 0.31, blue: 0.63, alpha: 1.0),
        emptyCell: SKColor(red: 0.13, green: 0.19, blue: 0.44, alpha: 1.0),
        filledCell: SKColor(red: 0.24, green: 0.76, blue: 0.50, alpha: 1.0),
        cellStroke: SKColor(red: 0.17, green: 0.24, blue: 0.53, alpha: 1.0),
        validHighlight: SKColor(red: 0.29, green: 0.88, blue: 0.62, alpha: 1.0),
        invalidHighlight: SKColor(red: 0.96, green: 0.31, blue: 0.36, alpha: 1.0),
        pieceA: SKColor(red: 0.36, green: 0.55, blue: 0.98, alpha: 1.0),
        pieceB: SKColor(red: 0.24, green: 0.76, blue: 0.50, alpha: 1.0),
        pieceC: SKColor(red: 0.63, green: 0.37, blue: 0.98, alpha: 1.0)
    )

    static func from(blockTheme: ThemeDefinition?, gridTheme: ThemeDefinition?, highContrast: Bool = false) -> GameVisualTheme {
        var theme = GameVisualTheme.default
        theme.highContrastMode = highContrast

        if let gridTheme {
            theme.boardBackground = SKColor(gridTheme.accentA)
            theme.emptyCell = SKColor(gridTheme.accentB)
            theme.cellStroke = SKColor(gridTheme.accentC)
            theme.filledCell = SKColor(gridTheme.accentC).withAlphaComponent(0.82)
        }

        if let blockTheme {
            theme.pieceA = SKColor(blockTheme.accentA)
            theme.pieceB = SKColor(blockTheme.accentB)
            theme.pieceC = SKColor(blockTheme.accentC)
            theme.filledCell = SKColor(blockTheme.accentA).withAlphaComponent(0.90)
            theme.validHighlight = SKColor(blockTheme.accentB).withAlphaComponent(0.90)
        }

        if highContrast {
            theme.boardBackground = SKColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 1.0)
            theme.emptyCell = SKColor(red: 0.16, green: 0.17, blue: 0.23, alpha: 1.0)
            theme.cellStroke = SKColor(red: 0.50, green: 0.54, blue: 0.66, alpha: 1.0)
            theme.filledCell = SKColor(red: 0.97, green: 0.84, blue: 0.24, alpha: 1.0)
            theme.validHighlight = SKColor(red: 0.14, green: 0.95, blue: 0.43, alpha: 1.0)
            theme.invalidHighlight = SKColor(red: 1.00, green: 0.25, blue: 0.19, alpha: 1.0)
        }

        return theme
    }

    func piecePalette(for kind: Piece.Kind) -> [SKColor] {
        if highContrastMode {
            return accessiblePalette(for: kind)
        }

        switch kind {
        case .i4:
            return [SKColor(red: 0.19, green: 0.83, blue: 0.96, alpha: 1.0), SKColor(red: 0.08, green: 0.63, blue: 0.90, alpha: 1.0), SKColor(red: 0.56, green: 0.93, blue: 0.98, alpha: 1.0)]
        case .i5:
            return [SKColor(red: 0.11, green: 0.74, blue: 1.00, alpha: 1.0), SKColor(red: 0.07, green: 0.52, blue: 0.90, alpha: 1.0), SKColor(red: 0.41, green: 0.86, blue: 1.00, alpha: 1.0)]
        case .o4:
            return [SKColor(red: 0.99, green: 0.82, blue: 0.24, alpha: 1.0), SKColor(red: 0.96, green: 0.65, blue: 0.19, alpha: 1.0), SKColor(red: 1.00, green: 0.90, blue: 0.40, alpha: 1.0)]
        case .t4:
            return [SKColor(red: 0.70, green: 0.43, blue: 1.0, alpha: 1.0), SKColor(red: 0.52, green: 0.31, blue: 0.94, alpha: 1.0), SKColor(red: 0.82, green: 0.60, blue: 1.0, alpha: 1.0)]
        case .l4, .j4:
            return [SKColor(red: 1.0, green: 0.57, blue: 0.19, alpha: 1.0), SKColor(red: 0.96, green: 0.43, blue: 0.15, alpha: 1.0), SKColor(red: 1.0, green: 0.72, blue: 0.30, alpha: 1.0)]
        case .s4:
            return [SKColor(red: 0.25, green: 0.90, blue: 0.54, alpha: 1.0), SKColor(red: 0.18, green: 0.75, blue: 0.45, alpha: 1.0), SKColor(red: 0.45, green: 0.98, blue: 0.67, alpha: 1.0)]
        case .z4:
            return [SKColor(red: 0.98, green: 0.29, blue: 0.36, alpha: 1.0), SKColor(red: 0.86, green: 0.18, blue: 0.27, alpha: 1.0), SKColor(red: 1.0, green: 0.45, blue: 0.51, alpha: 1.0)]
        case .plus5:
            return [SKColor(red: 1.00, green: 0.47, blue: 0.29, alpha: 1.0), SKColor(red: 0.92, green: 0.32, blue: 0.18, alpha: 1.0), SKColor(red: 1.00, green: 0.63, blue: 0.41, alpha: 1.0)]
        case .u5:
            return [SKColor(red: 0.22, green: 0.83, blue: 0.74, alpha: 1.0), SKColor(red: 0.14, green: 0.67, blue: 0.61, alpha: 1.0), SKColor(red: 0.40, green: 0.93, blue: 0.83, alpha: 1.0)]
        case .p5:
            return [SKColor(red: 0.98, green: 0.42, blue: 0.73, alpha: 1.0), SKColor(red: 0.86, green: 0.27, blue: 0.59, alpha: 1.0), SKColor(red: 1.00, green: 0.57, blue: 0.82, alpha: 1.0)]
        case .v5:
            return [SKColor(red: 0.99, green: 0.64, blue: 0.22, alpha: 1.0), SKColor(red: 0.91, green: 0.48, blue: 0.10, alpha: 1.0), SKColor(red: 1.00, green: 0.78, blue: 0.37, alpha: 1.0)]
        case .w5:
            return [SKColor(red: 0.32, green: 0.84, blue: 0.57, alpha: 1.0), SKColor(red: 0.20, green: 0.69, blue: 0.43, alpha: 1.0), SKColor(red: 0.50, green: 0.93, blue: 0.70, alpha: 1.0)]
        case .n5:
            return [SKColor(red: 0.44, green: 0.58, blue: 1.0, alpha: 1.0), SKColor(red: 0.30, green: 0.42, blue: 0.90, alpha: 1.0), SKColor(red: 0.61, green: 0.73, blue: 1.0, alpha: 1.0)]
        case .line3:
            return [SKColor(red: 0.19, green: 0.74, blue: 1.0, alpha: 1.0), SKColor(red: 0.12, green: 0.56, blue: 0.92, alpha: 1.0), SKColor(red: 0.40, green: 0.85, blue: 1.0, alpha: 1.0)]
        case .square2:
            return [SKColor(red: 1.0, green: 0.74, blue: 0.22, alpha: 1.0), SKColor(red: 0.96, green: 0.56, blue: 0.16, alpha: 1.0), SKColor(red: 1.0, green: 0.86, blue: 0.40, alpha: 1.0)]
        case .l3:
            return [SKColor(red: 0.99, green: 0.46, blue: 0.70, alpha: 1.0), SKColor(red: 0.89, green: 0.31, blue: 0.56, alpha: 1.0), SKColor(red: 1.0, green: 0.62, blue: 0.80, alpha: 1.0)]
        case .dot1:
            return [SKColor(red: 0.93, green: 0.97, blue: 0.29, alpha: 1.0), SKColor(red: 0.82, green: 0.86, blue: 0.20, alpha: 1.0), SKColor(red: 0.98, green: 1.0, blue: 0.43, alpha: 1.0)]
        }
    }

    private func accessiblePalette(for kind: Piece.Kind) -> [SKColor] {
        switch kind {
        case .i4:
            return [SKColor(red: 0.18, green: 0.82, blue: 1.0, alpha: 1.0), SKColor(red: 0.08, green: 0.64, blue: 0.93, alpha: 1.0), SKColor(red: 0.59, green: 0.93, blue: 1.0, alpha: 1.0)]
        case .i5:
            return [SKColor(red: 0.09, green: 0.82, blue: 1.0, alpha: 1.0), SKColor(red: 0.03, green: 0.61, blue: 0.93, alpha: 1.0), SKColor(red: 0.45, green: 0.91, blue: 1.0, alpha: 1.0)]
        case .o4:
            return [SKColor(red: 1.0, green: 0.89, blue: 0.26, alpha: 1.0), SKColor(red: 1.0, green: 0.67, blue: 0.17, alpha: 1.0), SKColor(red: 1.0, green: 0.96, blue: 0.54, alpha: 1.0)]
        case .t4:
            return [SKColor(red: 0.72, green: 0.49, blue: 1.0, alpha: 1.0), SKColor(red: 0.54, green: 0.31, blue: 0.95, alpha: 1.0), SKColor(red: 0.84, green: 0.68, blue: 1.0, alpha: 1.0)]
        case .l4, .j4:
            return [SKColor(red: 1.0, green: 0.58, blue: 0.16, alpha: 1.0), SKColor(red: 0.97, green: 0.39, blue: 0.08, alpha: 1.0), SKColor(red: 1.0, green: 0.79, blue: 0.42, alpha: 1.0)]
        case .s4:
            return [SKColor(red: 0.20, green: 0.96, blue: 0.58, alpha: 1.0), SKColor(red: 0.13, green: 0.79, blue: 0.44, alpha: 1.0), SKColor(red: 0.52, green: 1.0, blue: 0.70, alpha: 1.0)]
        case .z4:
            return [SKColor(red: 1.0, green: 0.32, blue: 0.32, alpha: 1.0), SKColor(red: 0.89, green: 0.18, blue: 0.18, alpha: 1.0), SKColor(red: 1.0, green: 0.57, blue: 0.57, alpha: 1.0)]
        case .plus5:
            return [SKColor(red: 1.0, green: 0.50, blue: 0.24, alpha: 1.0), SKColor(red: 0.93, green: 0.33, blue: 0.09, alpha: 1.0), SKColor(red: 1.0, green: 0.69, blue: 0.47, alpha: 1.0)]
        case .u5:
            return [SKColor(red: 0.20, green: 0.90, blue: 0.80, alpha: 1.0), SKColor(red: 0.10, green: 0.75, blue: 0.66, alpha: 1.0), SKColor(red: 0.45, green: 1.0, blue: 0.90, alpha: 1.0)]
        case .p5:
            return [SKColor(red: 1.0, green: 0.46, blue: 0.80, alpha: 1.0), SKColor(red: 0.91, green: 0.26, blue: 0.63, alpha: 1.0), SKColor(red: 1.0, green: 0.67, blue: 0.89, alpha: 1.0)]
        case .v5:
            return [SKColor(red: 1.0, green: 0.70, blue: 0.23, alpha: 1.0), SKColor(red: 0.95, green: 0.53, blue: 0.08, alpha: 1.0), SKColor(red: 1.0, green: 0.84, blue: 0.46, alpha: 1.0)]
        case .w5:
            return [SKColor(red: 0.35, green: 0.93, blue: 0.62, alpha: 1.0), SKColor(red: 0.22, green: 0.80, blue: 0.46, alpha: 1.0), SKColor(red: 0.58, green: 1.0, blue: 0.78, alpha: 1.0)]
        case .n5:
            return [SKColor(red: 0.47, green: 0.63, blue: 1.0, alpha: 1.0), SKColor(red: 0.31, green: 0.47, blue: 0.92, alpha: 1.0), SKColor(red: 0.69, green: 0.80, blue: 1.0, alpha: 1.0)]
        case .line3:
            return [SKColor(red: 0.23, green: 0.77, blue: 1.0, alpha: 1.0), SKColor(red: 0.11, green: 0.58, blue: 0.95, alpha: 1.0), SKColor(red: 0.56, green: 0.88, blue: 1.0, alpha: 1.0)]
        case .square2:
            return [SKColor(red: 1.0, green: 0.81, blue: 0.19, alpha: 1.0), SKColor(red: 0.98, green: 0.64, blue: 0.08, alpha: 1.0), SKColor(red: 1.0, green: 0.90, blue: 0.42, alpha: 1.0)]
        case .l3:
            return [SKColor(red: 1.0, green: 0.48, blue: 0.74, alpha: 1.0), SKColor(red: 0.93, green: 0.26, blue: 0.57, alpha: 1.0), SKColor(red: 1.0, green: 0.67, blue: 0.85, alpha: 1.0)]
        case .dot1:
            return [SKColor(red: 0.93, green: 0.99, blue: 0.26, alpha: 1.0), SKColor(red: 0.79, green: 0.87, blue: 0.09, alpha: 1.0), SKColor(red: 0.98, green: 1.0, blue: 0.48, alpha: 1.0)]
        }
    }

    func boardFilledColor(for kind: Piece.Kind) -> SKColor {
        piecePalette(for: kind).first ?? filledCell
    }

    var renderSignature: Int {
        var hasher = Hasher()
        hasher.combine(highContrastMode)
        combineColor(boardBackground, into: &hasher)
        combineColor(emptyCell, into: &hasher)
        combineColor(filledCell, into: &hasher)
        combineColor(cellStroke, into: &hasher)
        combineColor(validHighlight, into: &hasher)
        combineColor(invalidHighlight, into: &hasher)
        combineColor(pieceA, into: &hasher)
        combineColor(pieceB, into: &hasher)
        combineColor(pieceC, into: &hasher)
        return hasher.finalize()
    }

    private func combineColor(_ color: SKColor, into hasher: inout Hasher) {
        let components = rgbaComponents(for: color)
        hasher.combine(Int((components.red * 255).rounded()))
        hasher.combine(Int((components.green * 255).rounded()))
        hasher.combine(Int((components.blue * 255).rounded()))
        hasher.combine(Int((components.alpha * 255).rounded()))
    }

    private func rgbaComponents(for color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

struct GameSceneView: UIViewRepresentable {
    let state: GameState
    let recentEvents: [GameEvent]
    let dispatchSerial: Int
    let theme: GameVisualTheme
    let onPlacePiece: (Piece.ID, Cell) -> Void
    let onTapBoard: (Cell) -> Void

    final class Coordinator {
        var lastDispatchSerial: Int = -1
        var lastThemeSignature: Int = 0
        var lastViewSize: CGSize = .zero
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        skView.shouldCullNonVisibleNodes = true

        let scene = GameScene(size: CGSize(width: 600, height: 800))
        scene.scaleMode = .resizeFill
        scene.placePieceHandler = onPlacePiece
        scene.boardTapHandler = onTapBoard
        skView.presentScene(scene)

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? GameScene else { return }
        scene.placePieceHandler = onPlacePiece
        scene.boardTapHandler = onTapBoard

        let themeSignature = theme.renderSignature
        let shouldRender = context.coordinator.lastDispatchSerial != dispatchSerial ||
            context.coordinator.lastThemeSignature != themeSignature ||
            context.coordinator.lastViewSize != uiView.bounds.size
        guard shouldRender else { return }

        scene.render(state: state, recentEvents: recentEvents, dispatchSerial: dispatchSerial, theme: theme)
        context.coordinator.lastDispatchSerial = dispatchSerial
        context.coordinator.lastThemeSignature = themeSignature
        context.coordinator.lastViewSize = uiView.bounds.size
    }
}
