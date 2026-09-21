import SwiftUI

// Re-applies the in-app language to a subtree. macOS hosts sheets in their own window,
// which does not inherit the root `\.locale`, so they fall back to the system language.
private struct AppLanguageLocaleModifier: ViewModifier {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.deviceDefault.rawValue

    func body(content: Content) -> some View {
        content.environment(\.locale, AppLanguage(storedValue: appLanguage).locale)
    }
}

extension View {
    // Use on `.sheet` content so macOS sheets follow the in-app language picker.
    func appLanguageLocale() -> some View {
        modifier(AppLanguageLocaleModifier())
    }
}
