import SwiftUI

@MainActor
struct SettingsView: View {

    @ObservedObject private var loc = LocalizationManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            languageSection
            Divider()
            aboutSection
        }
        .frame(width: 460)
        .background(.background)
    }

    // MARK: - Language section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.Settings.language(loc.language))
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(Language.allCases) { lang in
                    languageButton(lang)
                }
            }
        }
        .padding(24)
    }

    private func languageButton(_ lang: Language) -> some View {
        let isSelected = loc.language == lang
        return Button {
            loc.language = lang
        } label: {
            HStack(spacing: 8) {
                Text(lang.flag)
                    .font(.system(size: 18))
                Text(lang.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color(.windowBackgroundColor))
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.clear : Color(.separatorColor), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AppStrings.Settings.about(loc.language))
                .font(.headline)

            HStack(alignment: .top, spacing: 20) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("IllusionApp")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(AppStrings.Settings.version(loc.language)) \(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(AppStrings.Settings.description(loc.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }

            Button {
                NSWorkspace.shared.open(URL(string: "https://github.com/HyagoHenrique/IllusionApp")!)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.square")
                    Text(AppStrings.Settings.viewOnGitHub(loc.language))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }
}
