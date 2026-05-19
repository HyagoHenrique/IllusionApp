import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var selectionWindow: SelectionOverlayWindow?
    private var mirrorWindowControllers: [MirrorWindowController] = []
    private var isSelecting = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon
        setupStatusBar()
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "IllusionApp")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Mirror a region…", action: #selector(startSelection), keyEquivalent: "m")
        menu.addItem(withTitle: "Unlock all screens", action: #selector(unlockAllScreens), keyEquivalent: "u")
        menu.addItem(withTitle: "Stop mirroring", action: #selector(stopMirroring), keyEquivalent: ".")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit IllusionApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    @objc private func unlockAllScreens() {
        print("[AppDelegate] unlockAllScreens called")
        for controller in mirrorWindowControllers {
            controller.viewModel.isLocked = false
        }
    }

    // MARK: - Actions

    @objc private func startSelection() {
        print("[AppDelegate] startSelection called, isSelecting=\(isSelecting)")

        // Prevent multiple simultaneous selections
        guard !isSelecting else {
            print("[AppDelegate] ERROR: Already selecting, ignoring")
            return
        }

        // Limit concurrent captures to 3 (system limitation with multiple concurrent screen captures)
        let maxConcurrentCaptures = 6
        guard mirrorWindowControllers.count < maxConcurrentCaptures else {
            print("[AppDelegate] ERROR: Maximum \(maxConcurrentCaptures) concurrent mirrors allowed")
            showAlert(
                title: "Limit Reached",
                message: "You can have a maximum of \(maxConcurrentCaptures) simultaneous mirror windows. Close one to add another."
            )
            return
        }

        guard let screen = NSScreen.main else {
            print("[AppDelegate] ERROR: NSScreen.main is nil")
            return
        }

        isSelecting = true

        // Clear previous selection window reference if it exists
        // (The window closes itself in the onSelection/onCancel callbacks)
        if selectionWindow != nil {
            print("[AppDelegate] Clearing reference to previous selection window")
            selectionWindow = nil
        }

        print("[AppDelegate] Creating SelectionOverlayWindow")
        let overlay = SelectionOverlayWindow(screen: screen)
        overlay.onSelection = { [weak self] region in
            print("[AppDelegate] onSelection callback - region: \(region)")
            guard let self else {
                print("[AppDelegate] ERROR: self is nil in onSelection callback")
                return
            }
            print("[AppDelegate] Opening mirror window")
            self.openMirror(for: region)
            print("[AppDelegate] onSelection callback completed")
            self.isSelecting = false
        }
        overlay.onCancel = { [weak self] in
            print("[AppDelegate] onCancel callback")
            self?.isSelecting = false
        }
        selectionWindow = overlay
        print("[AppDelegate] Showing selection overlay")
        overlay.show(on: screen)
    }

    @objc private func stopMirroring() {
        print("[AppDelegate] stopMirroring called")
        // Close all mirror windows
        Task {
            for controller in mirrorWindowControllers {
                controller.window?.close()
                await controller.viewModel.stopMirroring()
            }
            mirrorWindowControllers.removeAll()
        }
    }

    private func openMirror(for region: MirrorRegion) {
        print("[AppDelegate] openMirror called with region: \(region)")
        // Create a new ViewModel and Controller for each mirror window
        print("[AppDelegate] Creating new MirrorViewModel and MirrorWindowController")
        let viewModel = MirrorViewModel()
        let controller = MirrorWindowController(viewModel: viewModel)

        // Setup window close notification to remove from tracking array
        if let window = controller.window {
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                print("[AppDelegate] Mirror window closing, removing from tracking array")
                Task { @MainActor in
                    self?.mirrorWindowControllers.removeAll { $0.window == window }
                }
            }
        }

        mirrorWindowControllers.append(controller)

        print("[AppDelegate] Calling controller.show()")
        controller.show(for: region)
        print("[AppDelegate] openMirror completed")
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}
