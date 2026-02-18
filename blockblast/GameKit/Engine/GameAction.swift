import Foundation

enum GameAction {
    case startNewGame(mode: GameMode, seed: UInt64?)
    case placePiece(pieceID: Piece.ID, anchor: Cell)
    case selectPowerUp(type: PowerUpType)
    case tapBoard(position: Cell)
    case cancelPowerUpSelection
    case pause
    case resume
    case continueAfterGameOver
}
