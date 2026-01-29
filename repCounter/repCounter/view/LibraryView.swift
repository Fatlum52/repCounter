import SwiftUI
import SwiftData

struct LibraryView: View {
    
    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @Query private var sessionTemplates: [SessionTemplate]
    
    // MARK: - State
    @State private var showExerciseSheet: Bool = false
    @State private var showSessionSheet: Bool = false
    
    // MARK: - Exercise Templates
    private var allExerciseTemplates: [String] {
        // Defaults + User-Templates
        ExerciseTemplateStore.defaultTemplateNames + exerciseTemplates.map { $0.name }
    }
    
    // MARK: - Session Templates
    private var allSessionTemplates: [String] {
        // User-Templates
        let testTemplateName = "Push/Pull"  // Just the name as String
        return [testTemplateName] + sessionTemplates.map { $0.name }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Background()
            
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
        }
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
            NavigationStack {
                TemplateSheetView(
                    templates: allSessionTemplates,
                    title: "Session Templates",
                    onSelect: { name in }
                )
            }
        }
    }
}
