import AppKit
import SwiftUI

@MainActor
final class MirrorWindow: NSWindow {

    let viewModel: MirrorViewModel

    init(viewModel: MirrorViewModel) {
        self.viewModel = viewModel

        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configure()
        attachContent()
        observeClickThrough()
    }

    // MARK: - Setup

    private func configure() {
        level = .floating                   // always on top
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true  // drag anywhere on the content
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 100, height: 80)

        // Rounded corners will be set on the host layer in attachContent()
    }

    private func attachContent() {
        // Use SwiftUI for better UX and no flicker
        let mirrorView = MirrorView(viewModel: viewModel)
        let host = NSHostingView(rootView: mirrorView)
        contentView = host

        // Rounded corners on the host layer
        host.wantsLayer = true
        host.layer?.cornerRadius = 8
        host.layer?.masksToBounds = true
    }

    private func observeClickThrough() {
        viewModel.onClickThroughChange = { @MainActor [weak self] enabled in
            self?.ignoresMouseEvents = enabled
        }

        viewModel.onLockedChange = { @MainActor [weak self] locked in
            guard let self else { return }
            self.isMovableByWindowBackground = !locked

            // When locked: block resize
            if locked {
                // Block resizing when locked
                self.styleMask.remove(.resizable)
            } else {
                // Allow resizing when unlocked
                self.styleMask.insert(.resizable)
            }
        }

        viewModel.onOpacityChange = { @MainActor [weak self] opacity in
            self?.alphaValue = opacity
        }
    }

    // Allow the window to become key so controls respond to clicks.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Controller

@MainActor
final class MirrorWindowController: NSWindowController {

    let viewModel: MirrorViewModel

    init(viewModel: MirrorViewModel) {
        self.viewModel = viewModel
        let window = MirrorWindow(viewModel: viewModel)
        super.init(window: window)
    }

    required init?(coder: NSCoder) { nil }

    func show(for region: MirrorRegion) {
        Task { @MainActor in
            await viewModel.startMirroring(region: region)
            // Size the mirror window to match the aspect ratio of the captured region
            if let window, region.rect != .zero {
                let ratio = region.rect.width / region.rect.height
                let currentSize = window.frame.size
                let newHeight = currentSize.width / ratio
                window.setContentSize(NSSize(width: currentSize.width, height: newHeight))
            }
            showWindow(nil)
            window?.orderFrontRegardless()
        }
    }
}
