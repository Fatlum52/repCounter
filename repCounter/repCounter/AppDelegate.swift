import SwiftUI

/// Registers for remote notifications so CloudKit can push changes into a *running* app.
///
/// `NSPersistentCloudKitContainer` sets up its own CloudKit subscription, but the silent
/// pushes it relies on are only delivered once the app has an APNs token — and that
/// requires an explicit `registerForRemoteNotifications()` call. Without it the store
/// imports remote changes at launch only, which looks exactly like "sync is broken until
/// I rebuild and rerun".
///
/// This registers for *silent* pushes only, so it shows no permission prompt.
#if os(iOS)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
}
#elseif os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
    }
}
#endif
