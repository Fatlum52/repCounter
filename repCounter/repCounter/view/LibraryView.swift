//
//  LibraryView.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 19.01.2026.
//

import SwiftUI

struct LibraryView: View {
    
    @State private var showExerciseSheet: Bool = false
    
    var body: some View {
        
        VStack {
            Button("Exercises") {
                showExerciseSheet = true
            }
            
            Button("Training Sessions") {
                
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .font(.title3)
        .sheet(isPresented: $showExerciseSheet) {
            ExerciseSheetTemplateView(
                templates: [
                    .init("Bench Press"),
                    .init("Squat"),
                    .init("Deadlift"),
                    .init("Pull Ups"),
                    .init("Shoulder Press"),
                    .init("Pushup"),
                    .init("Pullup")
                ], onSelect: { _ in
                    // nothing
                }
            )
        }
    }
}

#Preview {
    LibraryView()
}
