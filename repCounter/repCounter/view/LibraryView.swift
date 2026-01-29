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
        .toolbarBackground(.hidden)
        .sheet(isPresented: $showExerciseSheet) {
            NavigationStack {
                TemplateSheetView(
                    templateType: .exercise,
                    userTemplates: exerciseTemplates.map { $0 as Any },
                    title: "Exercise Templates",
                    onSelect: { name in },
                    allowsEditing: true
                )
            }
        }
        .sheet(isPresented: $showSessionSheet) {
            NavigationStack {
                TemplateSheetView(
                    templateType: .session,
                    userTemplates: sessionTemplates.map { $0 as Any },
                    title: "Session Templates",
                    onSelect: { name in },
                    allowsEditing: true
                )
            }
        }
    }
}
