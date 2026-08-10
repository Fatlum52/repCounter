import SwiftUI

/// Re-applies the user-selected app language locale to a subtree.
///
/// Needed for `.sheet` content on **macOS**: sheets are hosted in a separate
/// presentation context (their own window) and do **not** inherit the
/// `\.locale` override set on the root in `repCounterApp`. Without this, sheet
/// content falls back to the Mac's system language instead of the in-app
/// language selection.
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
    /// Applies the user-selected app language locale to this subtree.
    ///
    /// Use on `.sheet` content so macOS sheets follow the in-app language
    /// picker rather than the system language.
    func appLanguageLocale() -> some View {
        modifier(AppLanguageLocaleModifier())
    }
}
