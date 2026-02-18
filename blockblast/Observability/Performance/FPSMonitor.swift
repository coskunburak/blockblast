import SpriteKit

final class FPSMonitor {
    private let label = SKLabelNode(fontNamed: "Menlo-Bold")
    private var lastTime: TimeInterval = 0
    private var frameCount: Int = 0

    init() {
        label.fontSize = 12
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.fontColor = .white
        label.zPosition = 10_000
        label.alpha = 0.8
        label.text = "FPS --"
    }

    func attach(to scene: SKScene) {
        guard label.parent == nil else { return }
        label.position = CGPoint(x: 12, y: scene.size.height - 12)
        scene.addChild(label)
    }

    func updateLayout(for scene: SKScene) {
        label.position = CGPoint(x: 12, y: scene.size.height - 12)
    }

    func tick(at currentTime: TimeInterval) {
        if lastTime == 0 {
            lastTime = currentTime
            return
        }

        frameCount += 1
        let delta = currentTime - lastTime
        guard delta >= 0.5 else { return }

        let fps = Double(frameCount) / delta
        label.text = String(format: "FPS %.0f", fps)
        frameCount = 0
        lastTime = currentTime
    }
}
