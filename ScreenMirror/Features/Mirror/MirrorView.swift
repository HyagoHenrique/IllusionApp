import SwiftUI

@MainActor
struct MirrorView: View {
    @ObservedObject var viewModel: MirrorViewModel
    @State private var showControls = false

    var body: some View {
        ZStack {
            frameContent
            if showControls { controlsOverlay }
        }
        .onHover { showControls = $0 }
        .ignoresSafeArea()
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var frameContent: some View {
        if let frame = viewModel.currentFrame {
            Image(decorative: frame, scale: 1.0)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                Image(systemName: "rectangle.dashed")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        if error.contains("permission") || error.contains("declined") {
                            Button("Open Privacy Settings") {
                                viewModel.openPrivacySettings()
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                        }
                    }
                } else {
                    Text("No region selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                // Lock status indicator
                Image(systemName: viewModel.isLocked ? "lock.fill" : "lock.open.fill")
                    .frame(width: 28, height: 28)
                    .help(viewModel.isLocked ? "Window is locked (right-click to unlock)" : "Window is unlocked (right-click to lock)")

                Button {
                    Task { @MainActor in
                        await viewModel.stopMirroring()
                        NSApplication.shared.keyWindow?.close()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 28, height: 28)
                }
                .help("Close mirror (right-click for menu)")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 12)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: showControls)
    }
}
