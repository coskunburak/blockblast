import SpriteKit

final class CellNode: SKShapeNode {
    let cell: Cell

    private var isFilled = false
    private var filledColorOverride: SKColor?
    private var theme: GameVisualTheme = .default
    private let fillLayer = SKShapeNode()
    private let bevelHighlightLayer = SKShapeNode()
    private let bevelShadowLayer = SKShapeNode()
    private let glossLayer = SKShapeNode()
    private var currentHighlight: HighlightStyle?
    private var currentSize: CGFloat = 0
    private var glossShimmerEnabled = true

    init(cell: Cell, size: CGFloat) {
        self.cell = cell
        super.init()
        self.name = "grid_cell_\(cell.row)_\(cell.column)"
        self.lineWidth = 1
        configureLayers()
        setCellSize(size)
        applyTheme(.default)
        setFilled(false)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func applyTheme(_ theme: GameVisualTheme) {
        self.theme = theme
        strokeColor = mixed(theme.cellStroke, with: .black, ratio: 0.16)
        if let highlight = currentHighlight {
            applyHighlightVisuals(style: highlight)
        } else {
            fillColor = theme.emptyCell
            refreshFilledLayers()
        }
    }

    func setCellSize(_ size: CGFloat) {
        guard abs(currentSize - size) > 0.1 else { return }
        currentSize = size

        let corner = max(4, size * 0.15)
        let rect = CGRect(
            x: -size / 2 + 1,
            y: -size / 2 + 1,
            width: size - 2,
            height: size - 2
        )
        path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
        fillLayer.path = path

        let half = (size - 2) / 2
        let inset = max(1.4, size * 0.08)

        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: -half + inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half * 0.08, y: half * 0.16))
        highlightPath.addLine(to: CGPoint(x: -half + inset, y: half * 0.10))
        highlightPath.closeSubpath()
        bevelHighlightLayer.path = highlightPath

        let shadowPath = CGMutablePath()
        shadowPath.move(to: CGPoint(x: half - inset, y: -half + inset))
        shadowPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        shadowPath.addLine(to: CGPoint(x: -half * 0.04, y: -half * 0.02))
        shadowPath.addLine(to: CGPoint(x: -half * 0.04, y: -half + inset))
        shadowPath.closeSubpath()
        bevelShadowLayer.path = shadowPath

        glossLayer.path = CGPath(
            ellipseIn: CGRect(
                x: -size * 0.18,
                y: size * 0.03,
                width: size * 0.36,
                height: size * 0.20
            ),
            transform: nil
        )
    }

    func setGlossShimmerEnabled(_ enabled: Bool) {
        guard glossShimmerEnabled != enabled else { return }
        glossShimmerEnabled = enabled

        if !enabled {
            glossLayer.removeAction(forKey: "cell_gloss_shimmer")
            if isFilled, currentHighlight == nil {
                glossLayer.alpha = min(glossLayer.alpha, 0.46)
            }
            return
        }

        if isFilled, currentHighlight == nil {
            runGlossShimmerIfNeeded()
        }
    }

    func setFilled(_ filled: Bool, colorOverride: SKColor? = nil) {
        if isFilled == filled, colorsMatch(filledColorOverride, colorOverride) {
            return
        }

        isFilled = filled
        filledColorOverride = colorOverride
        if let highlight = currentHighlight {
            applyHighlightVisuals(style: highlight)
        } else {
            fillColor = isFilled ? .clear : theme.emptyCell
            refreshFilledLayers()
        }
    }

    func setHighlight(_ style: HighlightStyle?) {
        guard currentHighlight != style else { return }
        currentHighlight = style

        switch style {
        case let .some(highlight):
            applyHighlightVisuals(style: highlight)
        case .none:
            fillColor = isFilled ? .clear : theme.emptyCell
            refreshFilledLayers()
        }
    }

    private func configureLayers() {
        fillLayer.lineWidth = 0
        fillLayer.zPosition = 1
        addChild(fillLayer)

        bevelHighlightLayer.lineWidth = 0
        bevelHighlightLayer.zPosition = 2
        bevelHighlightLayer.blendMode = .add
        addChild(bevelHighlightLayer)

        bevelShadowLayer.lineWidth = 0
        bevelShadowLayer.zPosition = 2
        addChild(bevelShadowLayer)

        glossLayer.lineWidth = 0
        glossLayer.zPosition = 3
        glossLayer.blendMode = .add
        addChild(glossLayer)
    }

    private func refreshFilledLayers() {
        guard isFilled else {
            fillLayer.alpha = 0
            bevelHighlightLayer.alpha = 0
            bevelShadowLayer.alpha = 0
            glossLayer.alpha = 0
            glossLayer.removeAction(forKey: "cell_gloss_shimmer")
            return
        }

        let base = filledColorOverride ?? theme.filledCell
        fillLayer.fillColor = base
        fillLayer.alpha = 1

        bevelHighlightLayer.fillColor = mixed(base, with: .white, ratio: 0.28).withAlphaComponent(0.84)
        bevelHighlightLayer.alpha = 1

        bevelShadowLayer.fillColor = mixed(base, with: .black, ratio: 0.22).withAlphaComponent(0.78)
        bevelShadowLayer.alpha = 1

        glossLayer.fillColor = SKColor.white.withAlphaComponent(0.24)
        if glossShimmerEnabled {
            glossLayer.alpha = 0.72
            runGlossShimmerIfNeeded()
        } else {
            glossLayer.alpha = 0.44
            glossLayer.removeAction(forKey: "cell_gloss_shimmer")
        }
    }

    private func runGlossShimmerIfNeeded() {
        guard glossShimmerEnabled else { return }
        guard glossLayer.action(forKey: "cell_gloss_shimmer") == nil else { return }

        let brighten = SKAction.fadeAlpha(to: 0.90, duration: 0.32)
        brighten.timingMode = .easeOut
        let dim = SKAction.fadeAlpha(to: 0.60, duration: 0.46)
        dim.timingMode = .easeInEaseOut
        let wait = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 1.8...3.2)))

        glossLayer.run(.repeatForever(.sequence([brighten, dim, wait])), withKey: "cell_gloss_shimmer")
    }

    private func applyHighlightVisuals(style: HighlightStyle) {
        switch style {
        case .valid:
            fillColor = theme.validHighlight
        case .invalid:
            fillColor = theme.invalidHighlight
        }
        fillLayer.alpha = 0
        bevelHighlightLayer.alpha = 0
        bevelShadowLayer.alpha = 0
        glossLayer.alpha = 0
        glossLayer.removeAction(forKey: "cell_gloss_shimmer")
    }

    private func colorsMatch(_ lhs: SKColor?, _ rhs: SKColor?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (left?, right?):
            let l = rgba(left)
            let r = rgba(right)
            return abs(l.red - r.red) < 0.001 &&
                abs(l.green - r.green) < 0.001 &&
                abs(l.blue - r.blue) < 0.001 &&
                abs(l.alpha - r.alpha) < 0.001
        default:
            return false
        }
    }

    private func mixed(_ lhs: SKColor, with rhs: SKColor, ratio: CGFloat) -> SKColor {
        let t = min(max(0, ratio), 1)
        let l = rgba(lhs)
        let r = rgba(rhs)
        return SKColor(
            red: l.red + ((r.red - l.red) * t),
            green: l.green + ((r.green - l.green) * t),
            blue: l.blue + ((r.blue - l.blue) * t),
            alpha: l.alpha + ((r.alpha - l.alpha) * t)
        )
    }

    private func rgba(_ color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

enum HighlightStyle {
    case valid
    case invalid
}
