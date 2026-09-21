import Foundation

/// User-selectable app language. Only languages the app is actually localized into are offered.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case german

    var id: String { rawValue }

    /// Best match between the device's preferred languages and the app's localizations.
    static var deviceDefault: AppLanguage {
        Bundle.main.preferredLocalizations.first == "de" ? .german : .english
    }

    /// Resolves a stored value, falling back to the device default for unknown
    /// values (including the removed `system` option).
    init(storedValue: String) {
        self = AppLanguage(rawValue: storedValue) ?? .deviceDefault
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en"
        case .german: "de"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    /// Language names are shown in their own language.
    var displayName: String {
        switch self {
        case .english: "English"
        case .german: "Deutsch"
        }
    }
}
