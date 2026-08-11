import SwiftUI

struct TimerView: View {

    @Environment(\.scenePhase) private var scenePhase
    @State private var model = TimerModel()

    /// Same accent the highlighted card surface uses.
    private let accent = Color(red: 1.0, green: 0.35, blue: 0.10)

    var body: some View {
        NavigationStack {
            ZStack {
                Background()

                VStack(spacing: 40) {
                    Spacer(minLength: 0)

                    if model.state == .idle {
                        durationPicker
                    } else {
                        countdownRing
                    }

                    controls

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .animation(.snappy, value: model.state)
            }
            .navigationTitle("Timer")
#if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
        }
        .onChange(of: scenePhase) { _, phase in
            model.handleScenePhase(phase)
        }
        .sensoryFeedback(.success, trigger: model.state == .finished)
    }

    // MARK: - Duration picker

    @ViewBuilder
    private var durationPicker: some View {
#if os(iOS)
        // The wheel style only exists on iOS; macOS gets steppers below.
        HStack(spacing: 0) {
            wheel(selection: $model.selectedMinutes, unit: "min")
            wheel(selection: $model.selectedSeconds, unit: "sec")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .cardSurface(cornerRadius: 20)
#else
        // Three rows over shared column widths. Everything is a fixed width so the
        // panel keeps its size when a value grows from one digit to two.
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text("min").frame(width: Self.columnWidth)
                Color.clear.frame(width: Self.gapWidth)
                Text("sec").frame(width: Self.columnWidth)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                numberField(selection: $model.selectedMinutes)
                Text(":")
                    .font(Self.numberFont)
                    .foregroundStyle(.secondary)
                    .frame(width: Self.gapWidth)
                numberField(selection: $model.selectedSeconds)
            }

            HStack(spacing: 0) {
                Stepper("", value: clamped($model.selectedMinutes), in: 0...59)
                    .labelsHidden()
                    .frame(width: Self.columnWidth)
                Color.clear.frame(width: Self.gapWidth)
                Stepper("", value: clamped($model.selectedSeconds), in: 0...59)
                    .labelsHidden()
                    .frame(width: Self.columnWidth)
            }
        }
        .padding(24)
        .cardSurface(cornerRadius: 20)
#endif
    }

#if os(iOS)
    private func wheel(selection: Binding<Int>, unit: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: selection) {
                ForEach(0..<60, id: \.self) { value in
                    Text(value.formatted()).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
    }
#else
    private static let columnWidth: CGFloat = 86
    private static let gapWidth: CGFloat = 22
    private static let numberFont = Font.system(size: 40, weight: .semibold, design: .rounded)

    /// Type-in field for one component. Two-digit padding is what gives the panel
    /// its "00:00" resting state.
    private func numberField(selection: Binding<Int>) -> some View {
        TextField("", value: clamped(selection), format: .number.precision(.integerLength(2...2)))
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(Self.numberFont)
            .monospacedDigit()
            .frame(width: Self.columnWidth)
    }

    /// Keeps typed input inside 0–59 — a text field accepts anything, so the bound
    /// value has to be the thing that enforces the range, not the stepper alone.
    private func clamped(_ source: Binding<Int>) -> Binding<Int> {
        Binding(
            get: { min(max(source.wrappedValue, 0), 59) },
            set: { source.wrappedValue = min(max($0, 0), 59) }
        )
    }
#endif

    // MARK: - Countdown

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: model.progress)

            VStack(spacing: 6) {
                Text(model.formattedRemaining)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if model.state == .paused {
                    Text("Paused")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if model.state == .finished {
                    Text("Timer finished")
                        .font(.subheadline)
                        .foregroundStyle(accent)
                }
            }
        }
        .frame(width: 260, height: 260)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            switch model.state {
            case .idle:
                Button("Start") { model.start() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canStart)

            case .running:
                Button("Cancel") { model.reset() }
                    .buttonStyle(.bordered)
                Button("Pause") { model.pause() }
                    .buttonStyle(.borderedProminent)

            case .paused:
                Button("Cancel") { model.reset() }
                    .buttonStyle(.bordered)
                Button("Resume") { model.resume() }
                    .buttonStyle(.borderedProminent)

            case .finished:
                Button("Done") { model.reset() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.large)
        .tint(accent)
    }
}

#Preview {
    TimerView()
}
