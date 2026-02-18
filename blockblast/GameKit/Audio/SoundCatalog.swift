import AudioToolbox
import Foundation

enum SoundEffect {
    case place
    case invalid
    case clear
    case comboTier1
    case comboTier2
    case comboTier3
    case bigCombo
    case pickup
    case uiTap
    case reward
    case objective

    var systemSoundID: SystemSoundID {
        switch self {
        case .place:
            return 1104
        case .invalid:
            return 1521
        case .clear:
            return 1025
        case .comboTier1:
            return 1021
        case .comboTier2:
            return 1028
        case .comboTier3:
            return 1031
        case .bigCombo:
            return 1057
        case .pickup:
            return 1155
        case .uiTap:
            return 1103
        case .reward:
            return 1111
        case .objective:
            return 1001
        }
    }
}
