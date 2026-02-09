import SwiftUI
import SwiftData

struct LibraryView: View {

    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @Query private var sessionTemplates: [SessionTemplate]

    // MARK: - State
    @State private var showExerciseSheet = false
    @State private var showSessionSheet = false

    // MARK: - Body
    var body: some View {
        ZStack {
            Background()

            ScrollView {
                VStack(spacing: 20) {
                    headerStats
                    exerciseSection
                    sessionSection
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
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

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 16) {
            StatBadge(value: "\(exerciseTemplates.count)", label: "Exercises", icon: "dumbbell.fill", color: .orange)
            StatBadge(value: "\(sessionTemplates.count)", label: "Sessions", icon: "calendar", color: .purple)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Exercise Templates Section
    private var exerciseSection: some View {
        Button {
            showExerciseSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.orange.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "dumbbell.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Exercise Templates")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(exerciseTemplates.count) template\(exerciseTemplates.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)

                // Preview of exercise names
                if !exerciseTemplates.isEmpty {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(exerciseTemplates.prefix(3)) { template in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(.orange.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(template.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }

                        if exerciseTemplates.count > 3 {
                            Text("+\(exerciseTemplates.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Session Templates Section
    private var sessionSection: some View {
        Button {
            showSessionSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.purple.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(.purple)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Session Templates")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(sessionTemplates.count) template\(sessionTemplates.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)

                // Preview of session templates
                if !sessionTemplates.isEmpty {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(sessionTemplates.prefix(3)) { template in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(.purple.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                    Text(template.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }

                                if !template.exerciseNames.isEmpty {
                                    Text(template.exerciseNames.prefix(3).joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .padding(.leading, 16)
                                }
                            }
                        }

                        if sessionTemplates.count > 3 {
                            Text("+\(sessionTemplates.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
