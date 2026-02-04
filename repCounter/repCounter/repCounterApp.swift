//
//  repCounterApp.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 06.01.2026.
//

import SwiftUI
import SwiftData

@main
struct repCounterApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Exercise.self,
            ExerciseTemplate.self,
            SessionTemplate.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
