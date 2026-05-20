import Foundation
import SwiftUI

@MainActor
final class MirrorViewModel: ObservableObject {

    @Published var currentFrame: CGImage?
    @Published var region: MirrorRegion?
    @Published var isLocked: Bool = false {
        didSet {
            onLockedChange?(isLocked)
            updateControlsVisibility()
        }
    }
    @Published var opacity: Double = 1.0 {
        didSet { onOpacityChange?(opacity) }
    }
    @Published var errorMessage: String?
    @Published var isPermissionDenied: Bool = false

    @Published var isHoveringMirror: Bool = false {
        didSet { updateControlsVisibility() }
    }
    @Published var isHoveringControls: Bool = false {
        didSet { updateControlsVisibility() }
    }

    var onLockedChange: (@MainActor (Bool) -> Void)?
    var onOpacityChange: (@MainActor (Double) -> Void)?
    var onControlsVisibilityChange: (@MainActor (Bool) -> Void)?
    var requestClose: (@MainActor () -> Void)?

    private var hideControlsTask: Task<Void, Never>?

    private let captureManager = ScreenCaptureManager()
    private var frameTask: Task<Void, Never>?

    // MARK: - Public API

    func startMirroring(region: MirrorRegion) async {
        self.region = region
        errorMessage = nil
        isPermissionDenied = false

        do {
            try await captureManager.startCapture(region: region)
            startDrainingFrames()
        } catch {
            let msg = error.localizedDescription
            if msg.contains("declined TCCs") || msg.contains("permission") {
                isPermissionDenied = true
                errorMessage = AppStrings.Mirror.permissionRequired(LocalizationManager.shared.language)
            } else {
                errorMessage = msg
            }
        }
    }

    func stopMirroring() async {
        frameTask?.cancel()
        frameTask = nil
        await captureManager.stopCapture()
        currentFrame = nil
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Frame pipeline

    private func updateControlsVisibility() {
        hideControlsTask?.cancel()
        let shouldShow = (isHoveringMirror || isHoveringControls) && !isLocked
        if shouldShow {
            onControlsVisibilityChange?(true)
        } else {
            hideControlsTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 180_000_000)
                guard let self, !Task.isCancelled else { return }
                if !(self.isHoveringMirror || self.isHoveringControls) {
                    self.onControlsVisibilityChange?(false)
                }
            }
        }
    }

    private func startDrainingFrames() {
        frameTask?.cancel()
        frameTask = Task { [weak self] in
            guard let self else { return }
            // CGImage is Sendable — no data race crossing the actor boundary.
            for await image in captureManager.frameStream {
                guard !Task.isCancelled else { break }
                self.currentFrame = image
            }
        }
    }
}
