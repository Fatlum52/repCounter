//
//  LibraryView.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 19.01.2026.
//

import SwiftUI

struct LibraryView: View {
    
    @State private var showExerciseSheet: Bool = false
    @State private var showSessionSheet: Bool = false
    
    var body: some View {
        
        VStack {
            Button("Exercises") {
                showExerciseSheet = true
            }
            
            Button("Training Sessions") {
                showSessionSheet = true
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .font(.title3)
        .sheet(isPresented: $showExerciseSheet) {
            // ExerciseSheetTemplateView
            //TemplateSheetView(
            //    templates: allTemplates,  // Defaults + User
            //    title: "Exercise Templates",
            //    onSelect: { name in addExercise(named: name) }
            //)
        }
        
        .sheet(isPresented: $showSessionSheet) {
            // ExerciseSheetTemplateView
            //TemplateSheetView(
            //    templates: allTemplates,  // Defaults + User
            //    title: "Session Templates",
            //    onSelect: { name in addExercise(named: name) }
            //)
        }
    }
}

#Preview {
    LibraryView()
}



