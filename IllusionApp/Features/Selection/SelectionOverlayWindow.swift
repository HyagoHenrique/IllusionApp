import AppKit
import SwiftUI

final class SelectionOverlayWindow: NSWindow {

    var onSelection: (@MainActor (MirrorRegion) -> Void)?
    var onCancel: (@MainActor () -> Void)?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // .statusBar sits above normal app windows without requiring special entitlements.
        // .screenSaverWindow would be ideal but requires a private entitlement on macOS 14+.
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    func show(on screen: NSScreen) {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
                        ?? CGMainDisplayID()

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
                let region = MirrorRegion(rect: nsRect, displayID: displayID)
                let callback = self.onSelection
                // Defer close to next run loop iteration to avoid releasing the window
                // while AppKit still holds autorelease references to it (use-after-free).
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
        makeKeyAndOrderFront(nil)
        // Ensure this window receives keyboard events for Esc
        makeFirstResponder(contentView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else { // 53 = Escape
            super.keyDown(with: event)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.close()
            self?.onCancel?()
        }
    }
}
