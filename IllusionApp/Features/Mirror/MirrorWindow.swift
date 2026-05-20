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
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 100, height: 80)
    }

    private func attachContent() {
        let mirrorView = MirrorView(viewModel: viewModel)
        let host = NSHostingView(rootView: mirrorView)
        contentView = host

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
            self.ignoresMouseEvents = locked

            if locked {
                self.styleMask.remove(.resizable)
            } else {
                self.styleMask.insert(.resizable)
            }
        }

        viewModel.onOpacityChange = { @MainActor [weak self] opacity in
            self?.alphaValue = opacity
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Controller

@MainActor
final class MirrorWindowController: NSWindowController {

    let viewModel: MirrorViewModel
    private var controlsWindow: MirrorControlsWindow?
    nonisolated(unsafe) private var frameObserver: NSObjectProtocol?

    init(viewModel: MirrorViewModel) {
        self.viewModel = viewModel
        let window = MirrorWindow(viewModel: viewModel)
        super.init(window: window)

        viewModel.onControlsVisibilityChange = { @MainActor [weak self] visible in
            self?.toggleControls(visible)
        }
        viewModel.requestClose = { @MainActor [weak self] in
            self?.controlsWindow?.orderOut(nil)
            self?.window?.close()
        }

        // Reposition controls window when mirror window moves or resizes
        frameObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.repositionControlsIfVisible() }
        }
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        if let frameObserver {
            NotificationCenter.default.removeObserver(frameObserver)
        }
    }

    func show(for region: MirrorRegion) {
        Task { @MainActor in
            await viewModel.startMirroring(region: region)
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

    // MARK: - Controls window management

    private func toggleControls(_ visible: Bool) {
        if visible {
            showControls()
        } else {
            controlsWindow?.orderOut(nil)
        }
    }

    private func showControls() {
        guard let mirrorWindow = window else { return }
        if controlsWindow == nil {
            controlsWindow = MirrorControlsWindow(viewModel: viewModel)
        }
        guard let cw = controlsWindow else { return }

        positionControlsWindow(cw, near: mirrorWindow)
        cw.orderFront(nil)
    }

    private func repositionControlsIfVisible() {
        guard let cw = controlsWindow, cw.isVisible, let mirrorWindow = window else { return }
        positionControlsWindow(cw, near: mirrorWindow)
    }

    private func positionControlsWindow(_ cw: NSWindow, near mirrorWindow: NSWindow) {
        let mirrorFrame = mirrorWindow.frame
        let controlsSize = cw.frame.size
        let gap: CGFloat = 8

        let x = mirrorFrame.midX - controlsSize.width / 2
        var y = mirrorFrame.minY - controlsSize.height - gap

        // If the controls would go below the screen, place above the mirror window instead.
        if let screen = mirrorWindow.screen, y < screen.visibleFrame.minY {
            y = mirrorFrame.maxY + gap
        }

        cw.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
