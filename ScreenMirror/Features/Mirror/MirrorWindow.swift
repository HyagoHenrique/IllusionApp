import AppKit
import SwiftUI
import AVFoundation
import Foundation
import ObjectiveC

@MainActor
final class MirrorWindow: NSWindow {

    let viewModel: MirrorViewModel
    private var displayView: ImageDisplayView?
    private var rightClickMonitor: Any?

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
        // Create container for display + controls
        let containerView = NSView()
        contentView = containerView
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.cgColor

        // Use AppKit directly instead of SwiftUI to avoid weak reference overhead
        let displayView = ImageDisplayView(frame: .zero)
        displayView.mirrorWindow = self
        self.displayView = displayView
        containerView.addSubview(displayView)

        // Create control bar at bottom
        let controlBar = NSView()
        controlBar.wantsLayer = true
        controlBar.layer?.backgroundColor = NSColor(white: 0.2, alpha: 0.9).cgColor
        containerView.addSubview(controlBar)

        // Lock button
        let lockButton = NSButton()
        lockButton.title = "🔓"
        lockButton.bezelStyle = .rounded
        lockButton.font = NSFont.systemFont(ofSize: 16)
        lockButton.target = self
        lockButton.action = #selector(handleLockButtonPress)
        controlBar.addSubview(lockButton)

        // Unlock button
        let unlockButton = NSButton()
        unlockButton.title = "🔒"
        unlockButton.bezelStyle = .rounded
        unlockButton.font = NSFont.systemFont(ofSize: 16)
        unlockButton.target = self
        unlockButton.action = #selector(handleUnlockButtonPress)
        controlBar.addSubview(unlockButton)

        // Layout buttons
        lockButton.translatesAutoresizingMaskIntoConstraints = false
        unlockButton.translatesAutoresizingMaskIntoConstraints = false
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        displayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Control bar at bottom, full width, 50 points height
            controlBar.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            controlBar.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            controlBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 50),

            // Display view takes rest of space
            displayView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            displayView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            displayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            displayView.bottomAnchor.constraint(equalTo: controlBar.topAnchor),

            // Button layout
            lockButton.leftAnchor.constraint(equalTo: controlBar.leftAnchor, constant: 8),
            lockButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            lockButton.widthAnchor.constraint(equalToConstant: 40),
            lockButton.heightAnchor.constraint(equalToConstant: 40),

            unlockButton.leftAnchor.constraint(equalTo: lockButton.rightAnchor, constant: 8),
            unlockButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            unlockButton.widthAnchor.constraint(equalToConstant: 40),
            unlockButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        // Store references for updates
        objc_setAssociatedObject(self, "lockButton", lockButton, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, "unlockButton", unlockButton, .OBJC_ASSOCIATION_RETAIN)

        // Rounded corners on container
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 8
        containerView.layer?.masksToBounds = true

        // Update display when frames arrive (no polling, no flicker)
        viewModel.onFrameReceived = { [weak self] frame in
            self?.displayView?.updateImage(frame)
        }
    }

    private var lockButtonPressTimer: Timer?
    private var unlockButtonPressTimer: Timer?

    @objc private func handleLockButtonPress() {
        // Start timer on first press, complete lock after 2s
        if lockButtonPressTimer == nil {
            lockButtonPressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.viewModel.isLocked = true
                    self?.lockButtonPressTimer = nil
                }
            }
        }
    }

    @objc private func handleUnlockButtonPress() {
        // Start timer on first press, complete unlock after 2s
        if unlockButtonPressTimer == nil {
            unlockButtonPressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.viewModel.isLocked = false
                    self?.unlockButtonPressTimer = nil
                }
            }
        }
    }

    private func observeClickThrough() {
        viewModel.onClickThroughChange = { @MainActor [weak self] enabled in
            self?.ignoresMouseEvents = enabled
        }

        viewModel.onLockedChange = { @MainActor [weak self] locked in
            guard let self else { return }
            self.isMovableByWindowBackground = !locked

            // When locked: pass left-clicks through, block resize
            self.ignoresMouseEvents = locked
            if locked {
                // Block resizing when locked
                self.styleMask.remove(.resizable)
            } else {
                // Allow resizing when unlocked
                self.styleMask.insert(.resizable)
            }

            // Register global right-click monitor when locked
            if locked {
                self.setupGlobalRightClickMonitor()
            } else {
                self.removeGlobalRightClickMonitor()
            }
        }

        viewModel.onOpacityChange = { @MainActor [weak self] opacity in
            self?.alphaValue = opacity
        }
    }

    private func setupGlobalRightClickMonitor() {
        // Remove old monitor if exists
        removeGlobalRightClickMonitor()

        // Add global right-click monitor that works even with ignoresMouseEvents = true
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return event }

            // Check if right-click is on our window using CGEvent mouse location
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = self.frame

            if NSPointInRect(mouseLocation, windowFrame) {
                // Show context menu
                self.showContextMenu()
                return nil // Consume the event
            }
            return event
        }
    }

    private func removeGlobalRightClickMonitor() {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
            rightClickMonitor = nil
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
        // Right-click shows context menu when unlocked
        // (When locked, global monitor handles it)
        mirrorWindow?.showContextMenu()
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
