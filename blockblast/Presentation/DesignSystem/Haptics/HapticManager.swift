import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    private var isEnabled = true

    private let placeImpact = UIImpactFeedbackGenerator(style: .light)
    private let invalidImpact = UINotificationFeedbackGenerator()
    private let clearImpact = UIImpactFeedbackGenerator(style: .medium)
    private let comboImpact = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    func prepare() {
        guard isEnabled else { return }
        placeImpact.prepare()
        invalidImpact.prepare()
        clearImpact.prepare()
        comboImpact.prepare()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            prepare()
        }
    }

    func place() {
        guard isEnabled else { return }
        placeImpact.impactOccurred(intensity: 0.72)
        placeImpact.prepare()
    }

    func invalid() {
        guard isEnabled else { return }
        invalidImpact.notificationOccurred(.warning)
        invalidImpact.prepare()
    }

    func clear() {
        guard isEnabled else { return }
        clearImpact.impactOccurred(intensity: 0.86)
        clearImpact.prepare()
    }

    func bigCombo() {
        guard isEnabled else { return }
        comboImpact.notificationOccurred(.success)
        comboImpact.prepare()
    }
}
