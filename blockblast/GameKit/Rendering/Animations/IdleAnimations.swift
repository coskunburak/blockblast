import SpriteKit

enum IdleAnimations {
    static func applyGentleFloat(to node: SKNode, amplitude: CGFloat = 3.0, duration: TimeInterval = 1.2) {
        guard node.action(forKey: "idle_motion") == nil else { return }

        let amp = max(1.2, amplitude * CGFloat.random(in: 0.86...1.24))
        let beat = max(0.8, duration * Double.random(in: 0.94...1.28))
        let initialDelay = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 0.0...0.55)))

        let rise = SKAction.moveBy(x: 0, y: amp, duration: beat)
        rise.timingMode = .easeInEaseOut
        let fall = SKAction.moveBy(x: 0, y: -amp, duration: beat)
        fall.timingMode = .easeInEaseOut
        let floatLoop = SKAction.sequence([rise, fall])

        let swayDistance = amp * CGFloat.random(in: 0.14...0.28)
        let swayOut = SKAction.moveBy(x: swayDistance, y: 0, duration: beat * 1.05)
        swayOut.timingMode = .easeInEaseOut
        let swayBack = SKAction.moveBy(x: -swayDistance, y: 0, duration: beat * 1.05)
        swayBack.timingMode = .easeInEaseOut
        let swayLoop = SKAction.sequence([swayOut, swayBack])

        let breathePeak = CGFloat.random(in: 1.015...1.032)
        let inhale = SKAction.scale(to: breathePeak, duration: beat * 0.98)
        inhale.timingMode = .easeInEaseOut
        let exhale = SKAction.scale(to: 1.0, duration: beat * 1.02)
        exhale.timingMode = .easeInEaseOut
        let breatheLoop = SKAction.sequence([inhale, exhale])

        let rotateAmount = CGFloat.random(in: 0.005...0.012)
        let tiltOut = SKAction.rotate(toAngle: rotateAmount, duration: beat * 1.12, shortestUnitArc: true)
        tiltOut.timingMode = .easeInEaseOut
        let tiltBack = SKAction.rotate(toAngle: -rotateAmount, duration: beat * 1.12, shortestUnitArc: true)
        tiltBack.timingMode = .easeInEaseOut
        let settle = SKAction.rotate(toAngle: 0, duration: beat * 0.90, shortestUnitArc: true)
        settle.timingMode = .easeInEaseOut
        let tiltLoop = SKAction.sequence([tiltOut, tiltBack, settle])

        let layeredMotion = SKAction.group([
            SKAction.repeatForever(floatLoop),
            SKAction.repeatForever(swayLoop),
            SKAction.repeatForever(breatheLoop),
            SKAction.repeatForever(tiltLoop)
        ])

        node.run(.sequence([initialDelay, layeredMotion]), withKey: "idle_motion")
    }

    static func stopFloat(on node: SKNode) {
        node.removeAction(forKey: "idle_motion")
    }
}
