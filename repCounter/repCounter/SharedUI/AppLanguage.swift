import Foundation

/// User-selectable app language. `system` follows the device setting.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case german

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .german: "de"
        }
    }

    var locale: Locale? {
        localeIdentifier.map(Locale.init(identifier:))
    }

    /// Language names are shown in their own language (except System, which is localized).
    var displayName: String {
        switch self {
        case .system: String(localized: "System")
        case .english: "English"
        case .german: "Deutsch"
        }
    }
}
