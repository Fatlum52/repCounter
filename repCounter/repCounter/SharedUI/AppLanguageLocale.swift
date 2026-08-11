import SwiftUI

// Re-applies the in-app language to a subtree. macOS hosts sheets in their own window,
// which does not inherit the root `\.locale`, so they fall back to the system language.
private struct AppLanguageLocaleModifier: ViewModifier {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    func body(content: Content) -> some View {
        if let locale = (AppLanguage(rawValue: appLanguage) ?? .system).locale {
            content.environment(\.locale, locale)
        } else {
            content
        }
    }
}

extension View {
    // Use on `.sheet` content so macOS sheets follow the in-app language picker.
    func appLanguageLocale() -> some View {
        modifier(AppLanguageLocaleModifier())
    }
}
