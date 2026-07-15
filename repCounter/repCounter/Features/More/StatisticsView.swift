import SwiftUI
import SwiftData

struct StatisticsView: View {

    @Query(sort: \Session.date, order: .forward) private var sessions: [Session]
    @Query(sort: \ExerciseTemplate.name) private var templates: [ExerciseTemplate]

    // Only definitions that were actually performed, most-trained first.
    private var performedTemplates: [ExerciseTemplate] {
        templates
            .filter { $0.timesPerformed > 0 }
            .sorted { $0.totalRepsAllTime > $1.totalRepsAllTime }
    }

    private var totalVolume: Double {
        templates.reduce(0) { $0 + $1.totalVolumeAllTime }
    }

    private var firstSessionDate: Date? { sessions.first?.date }

    var body: some View {
        ZStack {
            Background()

            ScrollView {
                VStack(spacing: 20) {
                    overviewHeader
                    exercisesSection
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Statistics")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
    }

    // MARK: - Overview

    private var overviewHeader: some View {
        HStack(spacing: 16) {
            StatBadge(value: "\(sessions.count)", label: "Total sessions", icon: "calendar", color: .purple)
            StatBadge(value: "\(performedTemplates.count)", label: "Exercises", icon: "dumbbell.fill", color: .orange)
            StatBadge(value: compactVolume, label: "Total volume", icon: "scalemass.fill")
        }
        .padding(.horizontal, 16)
    }

    private var compactVolume: String {
        totalVolume.formatted(.number.notation(.compactName).precision(.fractionLength(0...1))) + " kg"
    }

    // MARK: - First session + per-exercise breakdown

    @ViewBuilder
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let firstSessionDate {
                HStack {
                    Label("First session", systemImage: "flag.checkered")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(firstSessionDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .cardSurface(cornerRadius: 16, strokeColor: .gray.opacity(0.2), lineWidth: 1, shadow: false)
                .padding(.horizontal, 16)
            }

            if performedTemplates.isEmpty {
                EmptyStateView("No data yet")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else {
                ForEach(performedTemplates) { template in
                    exerciseRow(template)
                }
            }
        }
    }

    private func exerciseRow(_ template: ExerciseTemplate) -> some View {
        CardStyle {
            VStack(alignment: .leading, spacing: 10) {
                Text(template.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    StatBadge(value: "\(template.timesPerformed)", label: "Times performed", icon: "repeat")
                    StatBadge(value: "\(template.totalRepsAllTime)", label: "Total Reps", icon: "flame.fill", color: .orange)
                    StatBadge(
                        value: template.totalVolumeAllTime.formatted(.number.notation(.compactName).precision(.fractionLength(0...1))),
                        label: "Volume",
                        icon: "scalemass.fill"
                    )
                }
            }
        }
    }
}
