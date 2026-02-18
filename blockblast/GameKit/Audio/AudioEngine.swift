import AudioToolbox
import Foundation

final class AudioEngine {
    static let shared = AudioEngine()
    private var isEnabled = true
    private var lastPlayback: [SoundEffect: CFTimeInterval] = [:]

    private init() {}

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func play(_ effect: SoundEffect, minimumSpacing: TimeInterval = 0.03) {
        guard isEnabled else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if let last = lastPlayback[effect], now - last < minimumSpacing {
            return
        }
        lastPlayback[effect] = now
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
