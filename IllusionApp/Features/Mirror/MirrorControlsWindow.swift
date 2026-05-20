import AppKit
import SwiftUI

@MainActor
final class MirrorControlsWindow: NSPanel {

    init(viewModel: MirrorViewModel) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 50),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false

        let host = NSHostingView(rootView: MirrorControlsView(viewModel: viewModel))
        host.translatesAutoresizingMaskIntoConstraints = false
        contentView = host

        // Size the window to fit the SwiftUI content
        let fittingSize = host.fittingSize
        setContentSize(fittingSize)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
