import SwiftUI

struct MoreView: View {

    @AppStorage("appLanguage") private var appLanguage = AppLanguage.deviceDefault.rawValue

    // Resolves legacy/unknown stored values so the picker always shows a selection.
    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(storedValue: appLanguage) },
            set: { appLanguage = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Background()

                List {
                    Section {
                        NavigationLink {
                            StatisticsView()
                        } label: {
                            Label("Statistics", systemImage: "chart.bar.fill")
                        }
                    }

                    Section("Language") {
                        Picker("Language", selection: languageSelection) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("More")
#if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
        }
    }
}
