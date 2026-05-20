import Foundation
import SwiftUI

@MainActor
final class MirrorViewModel: ObservableObject {

    @Published var currentFrame: CGImage?
    @Published var region: MirrorRegion?
    @Published var isClickThrough: Bool = false {
        didSet { onClickThroughChange?(isClickThrough) }
    }
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

    @Published var isHoveringMirror: Bool = false {
        didSet { updateControlsVisibility() }
    }
    @Published var isHoveringControls: Bool = false {
        didSet { updateControlsVisibility() }
    }

    var onClickThroughChange: (@MainActor (Bool) -> Void)?
    var onLockedChange: (@MainActor (Bool) -> Void)?
    var onOpacityChange: (@MainActor (Double) -> Void)?
    var onControlsVisibilityChange: (@MainActor (Bool) -> Void)?
    var requestClose: (@MainActor () -> Void)?

    private var hideControlsTask: Task<Void, Never>?

    private let captureManager = ScreenCaptureManager()
    private var frameTask: Task<Void, Never>?

    // MARK: - Public API

    func startMirroring(region: MirrorRegion) async {
        print("[MirrorViewModel] startMirroring called with region: \(region)")
        self.region = region
        errorMessage = nil

        do {
            print("[MirrorViewModel] Calling captureManager.startCapture")
            try await captureManager.startCapture(region: region)
            print("[MirrorViewModel] startCapture succeeded, starting frame drain")
            startDrainingFrames()
            print("[MirrorViewModel] startMirroring completed successfully")
        } catch {
            print("[MirrorViewModel] ERROR in startCapture: \(error)")
            let errorMsg = error.localizedDescription
            if errorMsg.contains("declined TCCs") || errorMsg.contains("permission") {
                errorMessage = "Screen capture permission required. Tap the button below to allow access in System Settings, then try again."
            } else {
                errorMessage = errorMsg
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

    func updateRegion(_ region: MirrorRegion) async {
        self.region = region
        do {
            try await captureManager.updateRegion(region)
        } catch {
            errorMessage = error.localizedDescription
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
