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
                ExerciseTemplatesView()
            }
        }
        .sheet(isPresented: $showSessionSheet) {
            NavigationStack {
                SessionTemplatesView()
            }
        }
    }
}
