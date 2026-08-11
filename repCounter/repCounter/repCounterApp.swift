//
//  repCounterApp.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 06.01.2026.
//

import SwiftUI
import SwiftData
import CoreData

@main
struct repCounterApp: App {

    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    // Hooks up the APNs registration that CloudKit's live updates depend on.
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Exercise.self,
            ExerciseTemplate.self,
            SessionTemplate.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // uses the container from the entitlements
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed the default templates on first launch only.
            let context = container.mainContext
            let descriptor = FetchDescriptor<ExerciseTemplate>()
            let existingTemplates = try? context.fetch(descriptor)
            
            if existingTemplates?.isEmpty == true {
                for defaultName in ExerciseTemplateStore.defaultTemplateNames.reversed() {
                    ExerciseTemplateStore.shared.addTemplate(name: defaultName, in: context)
                }
                try context.save()
            }

            // Merge duplicates a previous launch synced in (see `deduplicate`).
            ExerciseTemplateStore.shared.deduplicate(in: context)

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            let language = AppLanguage(rawValue: appLanguage) ?? .system
            Group {
                if let locale = language.locale {
                    MainTabView()
                        .environment(\.locale, locale)
                } else {
                    MainTabView()
                }
            }
            .id(appLanguage) // rebuild the tree so a language switch applies immediately
            .task {
                // A launch-only dedup would miss a fresh device seeding its own defaults
                // seconds before the synced ones arrive.
                for await _ in NotificationCenter.default.notifications(
                    named: .NSPersistentStoreRemoteChange
                ) {
                    ExerciseTemplateStore.shared.deduplicate(in: sharedModelContainer.mainContext)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
