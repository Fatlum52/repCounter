import SwiftUI

struct MoreView: View {

    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

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
                        Picker("Language", selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language.rawValue)
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
