//
//  MainTabView.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 18.01.2026.
//

import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        TabView {
            
            Tab("Workouts", systemImage: "figure.run") {
                TrainingSessionView()
            }
            
            Tab("Library", systemImage: "building.columns.fill") {
                LibraryView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
