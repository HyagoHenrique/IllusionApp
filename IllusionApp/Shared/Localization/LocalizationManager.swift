import Foundation
import Combine

enum Language: String, CaseIterable, Identifiable {
    case english    = "en"
    case portuguese = "pt-BR"
    case spanish    = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:    return "English"
        case .portuguese: return "Português"
        case .spanish:    return "Español"
        }
    }

    var flag: String {
        switch self {
        case .english:    return "🇺🇸"
        case .portuguese: return "🇧🇷"
        case .spanish:    return "🇪🇸"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "AppLanguage")
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "AppLanguage") ?? ""
        language = Language(rawValue: saved) ?? .english
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("IllusionApp.languageDidChange")
}
