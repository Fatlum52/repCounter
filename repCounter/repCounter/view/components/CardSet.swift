import SwiftUI
import SwiftData

struct CardSet: View {
    
    @Bindable var exercise: Exercise
    @FocusState.Binding var focusedSetID: Exercise.ExerciseSet.ID?
    var onAddSet: () -> Exercise.ExerciseSet.ID?
    var onDeleteSet: (Exercise.ExerciseSet.ID) -> Void
    var repsBinding: (Exercise.ExerciseSet.ID) -> Binding<Int>
    var weightBinding: (Exercise.ExerciseSet.ID) -> Binding<Int>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("Set")
                Spacer()
                Text("Total Reps: \(exercise.totalReps)")
            }
            .font(.title3)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // Sets List
            ScrollViewReader { proxy in
                List {
                    let rows = Array(exercise.sets.enumerated())
                    
                    ForEach(rows, id: \.element.id) { index, set in
                        let displayNumber = index + 1
                        
                        // One Row in the SetCard
                        HStack {
                            // Set Number
                            Text("\(displayNumber). Set")
                                .font(.title3)
                            
                            // weight with kg label
                            TextField(
                                "0",
                                value: weightBinding(set.id),
                                format: .number
                            )
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .font(.title3)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                            Text("kg")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            // rep count with reps label
                            TextField(
                                "0",
                                value: repsBinding(set.id),
                                format: .number
                            )
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .font(.title3)
#if os(iOS)
                            .keyboardType(.numberPad)
                            .focused($focusedSetID, equals: set.id)
#endif
                            
                            Text("reps")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .id(set.id)
#if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                onDeleteSet(set.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
#elseif os(macOS)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteSet(set.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
#endif
                        .listRowSeparator(.visible, edges: .bottom)
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                        )
                        .listRowBackground(Color.clear)
                    }
                    
                    // ➕ Add Set Button as normal Row
                    HStack {
                        Spacer()
                        AddButtonCircle(
                            title: "add Set",
                            onAdd: {
                                if let newSetID = onAddSet() {
#if os(iOS)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        focusedSetID = newSetID
                                        withAnimation {
                                            proxy.scrollTo(newSetID, anchor: .center)
                                        }
                                    }
#endif
                                }
                            }
                        )
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                    )
                    .listRowBackground(Color.clear)
                    .id("addSetButton")
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .frame(height: cardHeight)
    }
    
    // MARK: - Helperfunctions
    
    // calculate card height - different row heights for iOS and macOS
    private var cardHeight: CGFloat {
#if os(iOS)
        let headerHeight: CGFloat = 40
        let addButtonHeight: CGFloat = 60
        let setRowHeight: CGFloat = 50
        let maxHeight: CGFloat = 400
#elseif os(macOS)
        let headerHeight: CGFloat = 30
        let addButtonHeight: CGFloat = 53
        let setRowHeight: CGFloat = 50
        let maxHeight: CGFloat = 300
#endif
        
        let totalHeight = headerHeight + addButtonHeight + (CGFloat(exercise.sets.count) * setRowHeight)
        return min(totalHeight, maxHeight)
    }
}
