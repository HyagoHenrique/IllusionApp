import SwiftUI
import AppKit

@MainActor
struct MirrorView: View {
    @ObservedObject var viewModel: MirrorViewModel
    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {
            frameContent
                .allowsHitTesting(!viewModel.isLocked)
        }
        .onHover { hovering in
            viewModel.isHoveringMirror = hovering && !viewModel.isLocked
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var frameContent: some View {
        if let frame = viewModel.currentFrame {
            Image(decorative: frame, scale: displayScale)
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

                        if viewModel.isPermissionDenied {
                            Button(AppStrings.Mirror.openPrivacySettings(loc.language)) {
                                viewModel.openPrivacySettings()
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                        }
                    }
                } else {
                    Text(AppStrings.Mirror.noRegionSelected(loc.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
