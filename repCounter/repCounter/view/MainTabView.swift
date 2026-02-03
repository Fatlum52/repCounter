//
//  MainTabView.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 18.01.2026.
//

import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        ZStack {
            Background()
            
            TabView {
                
                Tab("Workouts", systemImage: "figure.run") {
                    SessionView()
                }
                
                Tab("Library", systemImage: "building.columns.fill") {
                    LibraryView()
                }
            }
        }
#if os(iOS)
        .toolbarBackground(.hidden, for: .tabBar)
#endif
    }
}

#Preview {
    MainTabView()
}
