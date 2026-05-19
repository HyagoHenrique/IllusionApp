import AppKit
import SwiftUI

@MainActor
final class MirrorWindow: NSWindow {

    let viewModel: MirrorViewModel
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
        // Use SwiftUI for better UX and no flicker
        let mirrorView = MirrorView(viewModel: viewModel)
        let host = NSHostingView(rootView: mirrorView)
        contentView = host

        // Rounded corners on the host layer
        host.wantsLayer = true
        host.layer?.cornerRadius = 8
        host.layer?.masksToBounds = true

        // Add right-click gesture recognizer for context menu
        let rightClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(showContextMenu))
        rightClickGestureRecognizer.numberOfClicksRequired = 1
        host.addGestureRecognizer(rightClickGestureRecognizer)
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
