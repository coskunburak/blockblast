import CoreGraphics

final class DragController {
    private(set) var activePieceNode: PieceNode?
    private var touchOffset: CGPoint = .zero

    func beginDrag(pieceNode: PieceNode, touchLocationInScene: CGPoint) {
        guard let parent = pieceNode.parent else { return }
        activePieceNode = pieceNode
        let touchInParent = parent.convert(touchLocationInScene, from: pieceNode.scene ?? parent)
        let localTouchX = touchInParent.x - pieceNode.position.x
        let localTouchY = touchInParent.y - pieceNode.position.y

        touchOffset = CGPoint(
            x: -localTouchX,
            y: -localTouchY
        )
        pieceNode.startDragging()
    }

    func updateDrag(to touchLocationInScene: CGPoint) {
        guard let activePieceNode, let parent = activePieceNode.parent else { return }
        let touchInParent = parent.convert(touchLocationInScene, from: activePieceNode.scene ?? parent)

        let target = CGPoint(
            x: touchInParent.x + touchOffset.x,
            y: touchInParent.y + touchOffset.y
        )

        let current = activePieceNode.position
        let delta = CGPoint(x: target.x - current.x, y: target.y - current.y)
        let distance = hypot(delta.x, delta.y)
        let smoothing = min(0.62, max(0.28, 0.24 + (distance / 220)))

        activePieceNode.position = CGPoint(
            x: current.x + (delta.x * smoothing),
            y: current.y + (delta.y * smoothing)
        )

        let targetRotation = max(-0.07, min(0.07, delta.x / 240))
        activePieceNode.zRotation += (targetRotation - activePieceNode.zRotation) * 0.20
    }

    @discardableResult
    func endDrag() -> PieceNode? {
        defer { activePieceNode = nil }
        return activePieceNode
    }

    func cancelDrag() {
        guard let activePieceNode else { return }
        activePieceNode.returnHome(animated: true)
        self.activePieceNode = nil
    }
}
