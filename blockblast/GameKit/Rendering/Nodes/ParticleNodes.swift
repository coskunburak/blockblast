import SpriteKit

final class ParticlePool: SKNode {
    enum EmissionStyle {
        case burst
        case sparkle
        case mist
    }

    private var pool: [SKShapeNode] = []
    private let maxParticles: Int
    private var nextCandidateIndex: Int = 0
    private var pathCache: [Int: CGPath] = [:]

    init(maxParticles: Int = 64) {
        self.maxParticles = maxParticles
        super.init()
        for _ in 0..<maxParticles {
            let node = SKShapeNode(circleOfRadius: 3)
            node.isHidden = true
            node.lineWidth = 0
            node.blendMode = .add
            addChild(node)
            pool.append(node)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func emit(at point: CGPoint, color: SKColor, count: Int, style: EmissionStyle = .burst) {
        let drawCount = min(count, maxParticles)
        let profile = emissionProfile(for: style)

        for _ in 0..<drawCount {
            guard let node = nextFreeParticle() else { return }

            let radius = randomRadius(for: style)
            node.path = cachedCirclePath(radius: radius)
            node.isHidden = false
            node.alpha = CGFloat.random(in: profile.initialAlphaRange)
            node.fillColor = mixed(color, with: .white, amount: CGFloat.random(in: 0.22...0.52))
            node.strokeColor = .clear
            node.position = point
            node.zRotation = CGFloat.random(in: 0...(2 * .pi))
            switch style {
            case .sparkle:
                node.glowWidth = radius * 1.2
            case .mist:
                node.glowWidth = radius * 2.5
            case .burst:
                node.glowWidth = radius * 1.8
            }
            node.setScale(CGFloat.random(in: profile.scaleRange))
            node.removeAllActions()

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = randomSpeed(for: style)
            let firstLegDistance = speed * CGFloat.random(in: profile.firstLegDistanceMultiplier)
            let secondLegDistance = speed * CGFloat.random(in: profile.secondLegDistanceMultiplier)
            let downwardDrift = CGFloat.random(in: profile.downwardDriftRange)

            let firstMove = SKAction.moveBy(
                x: cos(angle) * firstLegDistance,
                y: sin(angle) * firstLegDistance,
                duration: TimeInterval(CGFloat.random(in: profile.firstLegDurationRange))
            )
            firstMove.timingMode = .easeOut

            let secondMove = SKAction.moveBy(
                x: cos(angle) * secondLegDistance,
                y: (sin(angle) * secondLegDistance) - downwardDrift,
                duration: TimeInterval(CGFloat.random(in: profile.secondLegDurationRange))
            )
            secondMove.timingMode = .easeInEaseOut

            let twinkle = twinkleAction(for: style, profile: profile)
            let fadeDuration = TimeInterval(CGFloat.random(in: profile.fadeDurationRange))

            let fade = SKAction.fadeOut(withDuration: fadeDuration)
            let shrink = SKAction.scale(
                to: CGFloat.random(in: profile.shrinkTargetRange),
                duration: fadeDuration
            )
            shrink.timingMode = .easeIn

            let floatLift = SKAction.moveBy(
                x: CGFloat.random(in: profile.floatLiftXRange),
                y: CGFloat.random(in: profile.floatLiftYRange),
                duration: TimeInterval(CGFloat.random(in: profile.floatLiftDurationRange))
            )
            floatLift.timingMode = .easeInEaseOut

            let travel = SKAction.sequence([firstMove, secondMove, floatLift])
            let spin = SKAction.rotate(
                byAngle: CGFloat.random(in: profile.spinRange),
                duration: TimeInterval(CGFloat.random(in: profile.spinDurationRange))
            )
            spin.timingMode = .easeInEaseOut

            node.run(.group([travel, twinkle, fade, shrink, spin])) { [weak node] in
                node?.isHidden = true
                node?.glowWidth = 0
                node?.removeAllActions()
            }
        }
    }

    private func nextFreeParticle() -> SKShapeNode? {
        guard !pool.isEmpty else { return nil }

        for _ in 0..<pool.count {
            let index = nextCandidateIndex
            nextCandidateIndex = (nextCandidateIndex + 1) % pool.count
            let node = pool[index]
            if node.isHidden {
                return node
            }
        }
        return nil
    }

    private func cachedCirclePath(radius: CGFloat) -> CGPath {
        let key = max(1, Int((radius * 100).rounded()))
        if let cached = pathCache[key] {
            return cached
        }

        let normalizedRadius = CGFloat(key) / 100
        let path = CGPath(
            ellipseIn: CGRect(
                x: -normalizedRadius,
                y: -normalizedRadius,
                width: normalizedRadius * 2,
                height: normalizedRadius * 2
            ),
            transform: nil
        )
        pathCache[key] = path
        return path
    }

    private func randomRadius(for style: EmissionStyle) -> CGFloat {
        switch style {
        case .burst:
            return CGFloat.random(in: 2.4...4.8)
        case .sparkle:
            return CGFloat.random(in: 1.5...3.0)
        case .mist:
            return CGFloat.random(in: 2.8...6.2)
        }
    }

    private func randomSpeed(for style: EmissionStyle) -> CGFloat {
        switch style {
        case .burst:
            return CGFloat.random(in: 66...112)
        case .sparkle:
            return CGFloat.random(in: 46...86)
        case .mist:
            return CGFloat.random(in: 26...56)
        }
    }

    private func twinkleAction(for style: EmissionStyle, profile: EmissionProfile) -> SKAction {
        switch style {
        case .sparkle:
            let flashIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.90...1.0), duration: 0.06)
            flashIn.timingMode = .easeOut
            let flashOut = SKAction.fadeAlpha(to: CGFloat.random(in: 0.56...0.76), duration: 0.08)
            flashOut.timingMode = .easeInEaseOut
            return SKAction.repeat(SKAction.sequence([flashIn, flashOut]), count: 3)
        case .mist:
            let breatheIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.62...0.78), duration: 0.18)
            breatheIn.timingMode = .easeInEaseOut
            let breatheOut = SKAction.fadeAlpha(to: CGFloat.random(in: 0.38...0.56), duration: 0.22)
            breatheOut.timingMode = .easeInEaseOut
            return SKAction.repeat(SKAction.sequence([breatheIn, breatheOut]), count: 2)
        case .burst:
            let pulseIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.84...0.96), duration: 0.07)
            pulseIn.timingMode = .easeOut
            let pulseOut = SKAction.fadeAlpha(to: CGFloat.random(in: 0.60...0.80), duration: 0.11)
            pulseOut.timingMode = .easeInEaseOut
            return SKAction.repeat(SKAction.sequence([pulseIn, pulseOut]), count: 2)
        }
    }

    private func emissionProfile(for style: EmissionStyle) -> EmissionProfile {
        switch style {
        case .burst:
            return EmissionProfile(
                initialAlphaRange: 0.74...1.0,
                scaleRange: 0.88...1.26,
                firstLegDistanceMultiplier: 0.20...0.27,
                secondLegDistanceMultiplier: 0.12...0.19,
                downwardDriftRange: 8...18,
                firstLegDurationRange: 0.12...0.20,
                secondLegDurationRange: 0.18...0.26,
                fadeDurationRange: 0.32...0.46,
                shrinkTargetRange: 0.14...0.38,
                floatLiftXRange: -7...7,
                floatLiftYRange: 5...14,
                floatLiftDurationRange: 0.12...0.20,
                spinRange: -0.9...0.9,
                spinDurationRange: 0.36...0.52
            )
        case .sparkle:
            return EmissionProfile(
                initialAlphaRange: 0.66...0.98,
                scaleRange: 0.82...1.12,
                firstLegDistanceMultiplier: 0.17...0.24,
                secondLegDistanceMultiplier: 0.08...0.14,
                downwardDriftRange: 6...14,
                firstLegDurationRange: 0.10...0.17,
                secondLegDurationRange: 0.16...0.24,
                fadeDurationRange: 0.28...0.40,
                shrinkTargetRange: 0.08...0.26,
                floatLiftXRange: -4...4,
                floatLiftYRange: 4...10,
                floatLiftDurationRange: 0.10...0.18,
                spinRange: -1.1...1.1,
                spinDurationRange: 0.30...0.46
            )
        case .mist:
            return EmissionProfile(
                initialAlphaRange: 0.52...0.84,
                scaleRange: 0.74...1.54,
                firstLegDistanceMultiplier: 0.16...0.22,
                secondLegDistanceMultiplier: 0.14...0.22,
                downwardDriftRange: 4...11,
                firstLegDurationRange: 0.16...0.24,
                secondLegDurationRange: 0.24...0.34,
                fadeDurationRange: 0.52...0.76,
                shrinkTargetRange: 0.24...0.58,
                floatLiftXRange: -10...10,
                floatLiftYRange: 10...22,
                floatLiftDurationRange: 0.22...0.34,
                spinRange: -0.48...0.48,
                spinDurationRange: 0.44...0.70
            )
        }
    }

    private func mixed(_ lhs: SKColor, with rhs: SKColor, amount: CGFloat) -> SKColor {
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

    private func rgbaComponents(for color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

private struct EmissionProfile {
    let initialAlphaRange: ClosedRange<CGFloat>
    let scaleRange: ClosedRange<CGFloat>
    let firstLegDistanceMultiplier: ClosedRange<CGFloat>
    let secondLegDistanceMultiplier: ClosedRange<CGFloat>
    let downwardDriftRange: ClosedRange<CGFloat>
    let firstLegDurationRange: ClosedRange<CGFloat>
    let secondLegDurationRange: ClosedRange<CGFloat>
    let fadeDurationRange: ClosedRange<CGFloat>
    let shrinkTargetRange: ClosedRange<CGFloat>
    let floatLiftXRange: ClosedRange<CGFloat>
    let floatLiftYRange: ClosedRange<CGFloat>
    let floatLiftDurationRange: ClosedRange<CGFloat>
    let spinRange: ClosedRange<CGFloat>
    let spinDurationRange: ClosedRange<CGFloat>
}
