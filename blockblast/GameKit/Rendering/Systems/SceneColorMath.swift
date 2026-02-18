import SpriteKit

enum SceneColorMath {
    static func blend(_ lhs: SKColor, with rhs: SKColor, amount: CGFloat) -> SKColor {
        let t = max(0, min(1, amount))
        let l = rgbaComponents(for: lhs)
        let r = rgbaComponents(for: rhs)
        return SKColor(
            red: l.red + ((r.red - l.red) * t),
            green: l.green + ((r.green - l.green) * t),
            blue: l.blue + ((r.blue - l.blue) * t),
            alpha: l.alpha + ((r.alpha - l.alpha) * t)
        )
    }

    static func rgbaComponents(for color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}
