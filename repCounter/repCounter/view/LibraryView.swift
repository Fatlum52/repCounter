import SwiftUI
import SwiftData

struct LibraryView: View {
    
    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseTemplates: [ExerciseTemplate]
    
    // MARK: - State
    @State private var showExerciseSheet: Bool = false
    @State private var showSessionSheet: Bool = false
    
    // MARK: - Templates
    private var allExerciseTemplates: [String] {
        // Defaults + User-Templates
        ExerciseTemplateStore.defaultTemplateNames + exerciseTemplates.map { $0.name }
    }
    
    // MARK: - Body
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
            NavigationStack {
                TemplateSheetView(
                    templates: allExerciseTemplates,
                    title: "Exercise Templates",
                    onSelect: { name in }
                )
            }
        }
        .sheet(isPresented: $showSessionSheet) {
            // TODO: Session
            Text("Session Templates - Coming Soon")
        }
    }
}
