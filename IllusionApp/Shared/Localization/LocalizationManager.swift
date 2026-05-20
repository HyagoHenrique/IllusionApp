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

/// Holds translations for a single string and resolves them by language.
/// Call as a function: `myString(currentLanguage)`.
struct LocalizedString: Sendable {
    let en: String
    let pt: String
    let es: String

    init(en: String, pt: String, es: String) {
        self.en = en
        self.pt = pt
        self.es = es
    }

    func callAsFunction(_ language: Language) -> String {
        switch language {
        case .english:    return en
        case .portuguese: return pt
        case .spanish:    return es
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    private static let storageKey = "AppLanguage"

    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        language = Language(rawValue: saved) ?? .english
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("IllusionApp.languageDidChange")
}
