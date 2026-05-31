import AppKit
import SwiftUI

/// A floating panel that covers one screen for region selection.
/// Uses NSPanel + nonactivatingPanel so it appears on any display
/// without requiring the app to be active.
final class SelectionOverlayWindow: NSPanel {

    var onSelection: (@MainActor (MirrorRegion) -> Void)?
    var onCancel: (@MainActor () -> Void)?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level            = .statusBar
        isOpaque         = false
        backgroundColor  = .clear
        isFloatingPanel  = true   // stays visible even when app is not active
        hidesOnDeactivate = false // don't hide when another app becomes active
        isMovable        = false
        isReleasedWhenClosed = false
        ignoresMouseEvents   = false
        collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    func show(on screen: NSScreen) {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                        as? CGDirectDisplayID ?? CGMainDisplayID()

        let selectionView = SelectionView(
            onSelection: { [weak self] rect in
                guard let self else { return }
                // rect is in SwiftUI (top-left) coords relative to the screen frame.
                // Convert to NSScreen coordinate space (bottom-left origin).
                let screenFrame = screen.frame
                let flippedY = screenFrame.height - rect.maxY
                let nsRect = CGRect(
                    x: screenFrame.origin.x + rect.origin.x,
                    y: screenFrame.origin.y + flippedY,
                    width: rect.width,
                    height: rect.height
                )
                let region   = MirrorRegion(rect: nsRect, displayID: displayID)
                let callback = self.onSelection
                DispatchQueue.main.async { [weak self] in
                    self?.close()
                    callback?(region)
                }
            },
            onCancel: { [weak self] in
                DispatchQueue.main.async {
                    self?.close()
                    self?.onCancel?()
                }
            }
        )

        contentView = NSHostingView(rootView: selectionView)
        setFrame(screen.frame, display: true)
        orderFrontRegardless()
    }

    // Panels can become key so Esc is handled via keyDown when this panel is key.
    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else { super.keyDown(with: event); return } // 53 = Esc
        DispatchQueue.main.async { [weak self] in
            self?.close()
            self?.onCancel?()
        }
    }
}
