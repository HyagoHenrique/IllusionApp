import AppKit
import SwiftUI
import AVFoundation
import Foundation
import ObjectiveC

@MainActor
final class MirrorWindow: NSWindow {

    let viewModel: MirrorViewModel
    private var displayView: ImageDisplayView?

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
        // Use AppKit directly instead of SwiftUI to avoid weak reference overhead
        let displayView = ImageDisplayView(frame: .zero)
        displayView.mirrorWindow = self
        self.displayView = displayView
        contentView = displayView

        // Rounded corners on the display layer
        displayView.wantsLayer = true
        displayView.layer?.cornerRadius = 8
        displayView.layer?.masksToBounds = true

        // Update display when frames arrive (no polling, no flicker)
        viewModel.onFrameReceived = { [weak self] frame in
            self?.displayView?.updateImage(frame)
        }
    }

    private func observeClickThrough() {
        viewModel.onClickThroughChange = { @MainActor [weak self] enabled in
            self?.ignoresMouseEvents = enabled
        }

        viewModel.onLockedChange = { @MainActor [weak self] locked in
            self?.isMovableByWindowBackground = !locked
        }

        viewModel.onOpacityChange = { @MainActor [weak self] opacity in
            self?.alphaValue = opacity
        }
    }

    @objc func showContextMenu() {
        let menu = NSMenu()

        // Lock/Unlock option
        let lockTitle = viewModel.isLocked ? "Unlock Window" : "Lock Window"
        menu.addItem(withTitle: lockTitle, action: #selector(toggleLock), keyEquivalent: "")

        menu.addItem(.separator())

        // Opacity submenu
        let opacityMenu = NSMenu(title: "Opacity")
        for opacity in [1.0, 0.75, 0.5, 0.25, 0.1] {
            let title = "\(Int(opacity * 100))%"
            let item = NSMenuItem(title: title, action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.tag = Int(opacity * 100)
            if abs(viewModel.opacity - opacity) < 0.01 {
                item.state = .on
            }
            opacityMenu.addItem(item)
        }
        menu.addItem(withTitle: "Opacity", action: nil, keyEquivalent: "")
        menu.setSubmenu(opacityMenu, for: menu.items.last!)

        menu.addItem(.separator())

        // Close option
        menu.addItem(withTitle: "Close", action: #selector(close), keyEquivalent: "")

        // Show menu at mouse location
        if let view = contentView {
            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent ?? NSEvent(), for: view)
        }
    }

    @objc private func toggleLock() {
        viewModel.isLocked.toggle()
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        viewModel.opacity = Double(sender.tag) / 100.0
    }

    // Allow the window to become key so controls respond to clicks.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Image Display View

@MainActor
final class ImageDisplayView: NSView {
    private var currentImage: CGImage?
    weak var mirrorWindow: MirrorWindow?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        // Use CALayer directly for simple image display - no SwiftUI overhead
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.isOpaque = true
    }

    func updateImage(_ image: CGImage) {
        self.currentImage = image
        // Draw directly on the layer
        DispatchQueue.main.async { [weak self] in
            self?.layer?.contents = image
            self?.setNeedsDisplay(self?.bounds ?? .zero)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let image = currentImage else {
            NSColor.black.setFill()
            dirtyRect.fill()
            return
        }

        // Draw image to fill the view
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high

        let imageRect = NSRect(origin: .zero, size: CGSize(width: image.width, height: image.height))
        let viewRect = self.bounds
        let scaledRect = AVMakeRect(aspectRatio: imageRect.size, insideRect: viewRect)

        let nsImage = NSImage(cgImage: image, size: NSZeroSize)
        nsImage.draw(in: scaledRect)
    }

    // MARK: - Mouse Events

    override func rightMouseDown(with event: NSEvent) {
        // Right-click always shows context menu (even when locked)
        mirrorWindow?.showContextMenu()
    }

    override func mouseDown(with event: NSEvent) {
        // Left-click passthrough when locked
        if let window = mirrorWindow, window.viewModel.isLocked {
            // When locked, pass left-click through to window behind
            // Do NOT call super - this prevents the click from being handled by this window
            return
        }
        // When unlocked, handle normally
        super.mouseDown(with: event)
    }
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
