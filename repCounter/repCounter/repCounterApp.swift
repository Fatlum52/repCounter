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
            TrainingSession.self,
            Exercise.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
