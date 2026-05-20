import SwiftUI
import AppKit

@MainActor
struct MirrorControlsView: View {
    @ObservedObject var viewModel: MirrorViewModel
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 14) {
            Menu {
                ForEach([1.0, 0.75, 0.5, 0.25, 0.1], id: \.self) { opacity in
                    Button("\(Int(opacity * 100))%") {
                        viewModel.opacity = opacity
                    }
                }
            } label: {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(AppStrings.Mirror.adjustOpacity(loc.language))

            Button {
                viewModel.isLocked = true
            } label: {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .help(AppStrings.Mirror.clickToLock(loc.language))

            Button {
                Task { @MainActor in
                    await viewModel.stopMirroring()
                    viewModel.requestClose?()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .help(AppStrings.Mirror.closeMirror(loc.language))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
        .onHover { hovering in
            viewModel.isHoveringControls = hovering
        }
    }
}
