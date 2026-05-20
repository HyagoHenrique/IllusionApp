import ScreenCaptureKit
import CoreMedia
import CoreImage
import AppKit

@MainActor
final class ScreenCaptureManager: NSObject, ObservableObject {

    @Published var isCapturing = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    private var stream: SCStream?
    private var streamOutput: CaptureStreamOutput?
    private var framesContinuation: AsyncStream<CGImage>.Continuation?

    // Publishes CGImage — Sendable, safe to cross actor boundaries in Swift 6.
    private(set) var frameStream: AsyncStream<CGImage> = AsyncStream { _ in }

    enum AuthorizationStatus {
        case notDetermined, authorized, denied
    }

    // MARK: - Stream lifecycle

    func startCapture(region: MirrorRegion) async throws {
        if isCapturing { await stopCapture() }

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            authorizationStatus = .authorized
        } catch let error as SCStreamError {
            authorizationStatus = .denied
            throw error
        } catch {
            authorizationStatus = .denied
            throw error
        }

        guard let display = content.displays.first(where: { $0.displayID == region.displayID })
                ?? content.displays.first else {
            throw CaptureError.displayNotFound
        }

        framesContinuation?.finish()
        let (newFrameStream, continuation) = AsyncStream<CGImage>.makeStream()
        frameStream = newFrameStream
        framesContinuation = continuation

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = buildStreamConfig(region: region, display: display)

        let output = CaptureStreamOutput(continuation: continuation)
        self.streamOutput = output

        let newStream = SCStream(filter: filter, configuration: config, delegate: output)
        try newStream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try await newStream.startCapture()

        self.stream = newStream
        isCapturing = true
    }

    func stopCapture() async {
        guard isCapturing, let stream else { return }
        framesContinuation?.finish()
        framesContinuation = nil
        try? await stream.stopCapture()
        self.stream = nil
        self.streamOutput = nil
        isCapturing = false
    }

    // MARK: - Private

    private func buildStreamConfig(region: MirrorRegion, display: SCDisplay) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()

        guard let screen = NSScreen.screens.first(where: {
            let id = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return id == region.displayID
        }) ?? NSScreen.main else {
            return config
        }

        let scaleFactor = screen.backingScaleFactor
        // sourceRect must be in points (display coordinate space), not pixels
        let sourceRect = region.rect.toScreenCaptureCoordinates(in: screen)

        config.sourceRect = sourceRect
        // Output dimensions in physical pixels for full resolution
        config.width = Int(sourceRect.width * scaleFactor)
        config.height = Int(sourceRect.height * scaleFactor)
        // 60 FPS for smooth playback
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        config.capturesAudio = false

        return config
    }

    enum CaptureError: LocalizedError {
        case displayNotFound
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .displayNotFound: return "Could not find the target display."
            case .permissionDenied: return "Screen capture permission was denied. Please allow access in System Settings."
            }
        }
    }
}

// MARK: - Stream output handler (SCKit background queue)

// Runs on SCKit's background queue. Converts CMSampleBuffer → CGImage here so we
// never send a non-Sendable type across the actor boundary. CGImage is Sendable.
private final class CaptureStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let continuation: AsyncStream<CGImage>.Continuation
    // CIContext is expensive to create and thread-safe to reuse.
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    init(continuation: AsyncStream<CGImage>.Continuation) {
        self.continuation = continuation
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, buffer.isValid else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        continuation.yield(cgImage)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        continuation.finish()
    }
}
