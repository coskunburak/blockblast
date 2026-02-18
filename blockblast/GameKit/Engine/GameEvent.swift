import Foundation

enum GameEvent: Equatable {
    case gameStarted(mode: GameMode)
    case piecePlaced(pieceID: Piece.ID)
    case linesCleared(count: Int)
    case comboChanged(Int)
    case comboTriggered(multiplier: Int, chain: Int)
    case powerUpEarned(PowerUpType, newCount: Int)
    case powerUpInventoryFull(PowerUpType)
    case powerUpSelected(PowerUpType)
    case powerUpApplied(PowerUpType)
    case powerUpCancelled
    case inventoryUpdated(PowerUpType, newCount: Int)
    case scoreChanged(delta: Int, total: Int)
    case invalidMove
    case gameOver(finalScore: Int)
    case continuedFromGameOver
    case paused
    case resumed
}
