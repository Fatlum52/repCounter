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
            
            // Initialize default exercise templates ONLY on first app launch
            let context = container.mainContext
            let descriptor = FetchDescriptor<ExerciseTemplate>()
            let existingTemplates = try? context.fetch(descriptor)
            
            // If NO templates exist at all → First launch → Create defaults
            // If templates exist → Already initialized → Do nothing
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
                // A launch-only dedup would miss the common case: a fresh device
                // seeds its own defaults, then the synced ones arrive seconds later.
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
