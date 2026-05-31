import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var selectionPanels: [SelectionOverlayWindow] = []
    private var escMonitor: Any?
    private var mirrorWindowControllers: [MirrorWindowController] = []
    private var isSelecting = false
    private var settingsWindowController: SettingsWindowController?
    private var languageCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()

        // Rebuild menu whenever language changes
        languageCancellable = NotificationCenter.default
            .publisher(for: .languageDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.setupStatusBar() }
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        let l = LocalizationManager.shared.language

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem?.button?.image = NSImage(
                systemSymbolName: "rectangle.on.rectangle",
                accessibilityDescription: "IllusionApp"
            )
        }

        let menu = NSMenu()
        menu.addItem(withTitle: AppStrings.Menu.mirrorRegion(l),    action: #selector(startSelection),               keyEquivalent: "m")
        menu.addItem(withTitle: AppStrings.Menu.unlockAllScreens(l), action: #selector(unlockAllScreens),            keyEquivalent: "u")
        menu.addItem(withTitle: AppStrings.Menu.stopMirroring(l),   action: #selector(stopMirroring),               keyEquivalent: ".")
        menu.addItem(.separator())
        menu.addItem(withTitle: AppStrings.Menu.settings(l),        action: #selector(openSettings),                keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: AppStrings.Menu.quit(l),            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.show()
    }

    @objc private func unlockAllScreens() {
        for controller in mirrorWindowControllers {
            controller.viewModel.isLocked = false
        }
    }

    @objc private func startSelection() {
        let l = LocalizationManager.shared.language

        guard !isSelecting else { return }

        let maxConcurrentCaptures = 6
        guard mirrorWindowControllers.count < maxConcurrentCaptures else {
            showAlert(
                title: AppStrings.Alert.limitReachedTitle(l),
                message: AppStrings.Alert.limitReachedMessage(l, max: maxConcurrentCaptures)
            )
            return
        }

        isSelecting = true
        dismissSelectionPanels()

        // One NSPanel per screen — NSPanel with nonactivatingPanel + isFloatingPanel
        // is the most reliable way to cover secondary monitors in a menu-bar app.
        for screen in NSScreen.screens {
            let panel = SelectionOverlayWindow(screen: screen)
            panel.onSelection = { [weak self] region in
                guard let self else { return }
                self.dismissSelectionPanels()
                self.openMirror(for: region)
                self.isSelecting = false
            }
            panel.onCancel = { [weak self] in
                self?.dismissSelectionPanels()
                self?.isSelecting = false
            }
            selectionPanels.append(panel)
            panel.show(on: screen)
        }

        // Global Esc monitor so pressing Escape on any screen cancels selection.
        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return } // 53 = Esc
            DispatchQueue.main.async {
                self?.dismissSelectionPanels()
                self?.isSelecting = false
            }
        }
    }

    @objc private func stopMirroring() {
        Task {
            for controller in mirrorWindowControllers {
                controller.window?.close()
                await controller.viewModel.stopMirroring()
            }
            mirrorWindowControllers.removeAll()
        }
    }

    // MARK: - Helpers

    private func dismissSelectionPanels() {
        selectionPanels.forEach { $0.close() }
        selectionPanels = []
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }

    private func openMirror(for region: MirrorRegion) {
        let viewModel = MirrorViewModel()
        let controller = MirrorWindowController(viewModel: viewModel)

        if let window = controller.window {
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.mirrorWindowControllers.removeAll { $0.window == window } }
            }
        }

        mirrorWindowControllers.append(controller)
        controller.show(for: region)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: AppStrings.Alert.ok(LocalizationManager.shared.language))
        alert.runModal()
    }
}
