import SwiftUI

struct TaskSettingsSection: View {
    @ObservedObject var settings: ParentSettings
    let onSave: () -> Void

    private let allUppercase = (65...90).map { String(UnicodeScalar($0)!) }
    private let allLowercase = (97...122).map { String(UnicodeScalar($0)!) }
    @State private var showUppercase = true

    private var activeSet: [String] { Set(settings.activeLetterArray) }

    var body: some View {
        Section {
            // Letter selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Letters to Practice")
                    .font(Theme.Fonts.parentBody())

                Picker("Case", selection: $showUppercase) {
                    Text("Uppercase").tag(true)
                    Text("Lowercase").tag(false)
                }
                .pickerStyle(.segmented)

                let letters = showUppercase ? allUppercase : allLowercase
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                    ForEach(letters, id: \.self) { letter in
                        let selected = activeSet.contains(letter)
                        Button(action: { toggleLetter(letter) }) {
                            Text(letter)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .background(selected ? Color.erBlue : Color.erBackground)
                                .foregroundColor(selected ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            // Attempts per session
            Stepper(
                "Attempts per session: \(Int(settings.attemptsPerSession))",
                value: Binding(
                    get: { Int(settings.attemptsPerSession) },
                    set: { settings.attemptsPerSession = Int16($0); onSave() }
                ),
                in: 5...20
            )

            // Passing threshold
            VStack(alignment: .leading, spacing: 6) {
                Text("Passing threshold: \(Int(settings.passingThreshold * 100))%")
                    .font(Theme.Fonts.parentBody())
                Slider(
                    value: Binding(
                        get: { settings.passingThreshold },
                        set: { settings.passingThreshold = $0; onSave() }
                    ),
                    in: 0.40...0.90,
                    step: 0.05
                )
                .tint(.erBlue)
            }

            // Quality multiplier
            Toggle(
                "Quality multiplier",
                isOn: Binding(
                    get: { settings.qualityMultiplierEnabled },
                    set: { settings.qualityMultiplierEnabled = $0; onSave() }
                )
            )
            if settings.qualityMultiplierEnabled {
                Text("60–74% → 1× · 75–89% → 1.25× · 90%+ → 1.5×")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Auto progression
            Toggle(
                "Auto-advance phases",
                isOn: Binding(
                    get: { settings.autoProgressionEnabled },
                    set: { settings.autoProgressionEnabled = $0; onSave() }
                )
            )
            if settings.autoProgressionEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Advance when rolling avg ≥ \(Int(settings.progressionThreshold * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { settings.progressionThreshold },
                            set: { settings.progressionThreshold = $0; onSave() }
                        ),
                        in: 0.70...0.95,
                        step: 0.05
                    )
                    .tint(.erGreen)
                }
            }

        } header: {
            Label("Task Settings", systemImage: "pencil")
        }
    }

    private func toggleLetter(_ letter: String) {
        var active = settings.activeLetterArray
        if active.contains(letter) {
            // Keep at least one letter active
            guard active.count > 1 else { return }
            active.removeAll { $0 == letter }
        } else {
            active.append(letter)
        }
        settings.activeLetterArray = active.sorted()
        onSave()
    }
}
