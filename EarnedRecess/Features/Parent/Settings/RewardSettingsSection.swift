import SwiftUI

struct RewardSettingsSection: View {
    @ObservedObject var settings: ParentSettings
    @ObservedObject var child: ChildProfile
    let onSave: () -> Void
    let onResetBalance: () -> Void

    @State private var showResetConfirm = false

    private var appModeLabel: String {
        switch settings.appMode {
        case "writeToWatch": return "Write to Watch Only"
        case "both": return "Practice, Earn & Write to Watch"
        default: return "Practice & Earn Minutes"
        }
    }

    private var appModeDescription: String {
        switch settings.appMode {
        case "writeToWatch": return "Child skips earning and writes a title to unlock any video directly."
        case "both": return "Child earns minutes by practicing and must write a title before watching."
        default: return "Child practices letters to earn Star Minutes, then spends them to watch."
        }
    }

    var body: some View {
        Section {
            Picker("App Mode", selection: Binding(
                get: { settings.appMode },
                set: { settings.appMode = $0; onSave() }
            )) {
                Text("Practice & Earn Minutes").tag("standard")
                Text("Write to Watch Only").tag("writeToWatch")
                Text("Practice, Earn & Write to Watch").tag("both")
            }
            .pickerStyle(.menu)
            .tint(.erBlue)

            Text(appModeDescription)
                .font(Theme.Fonts.parentCaption())
                .foregroundColor(.secondary)

            // Star minutes per session
            Stepper(
                "Star minutes per session: \(Int(settings.timerDurationMinutes))",
                value: Binding(
                    get: { Int(settings.timerDurationMinutes) },
                    set: { settings.timerDurationMinutes = Int32($0); onSave() }
                ),
                in: 5...60,
                step: 5
            )

            // Daily maximum
            Stepper(
                "Daily maximum: \(Int(settings.maxDailyMinutes)) min",
                value: Binding(
                    get: { Int(settings.maxDailyMinutes) },
                    set: { settings.maxDailyMinutes = Int32($0); onSave() }
                ),
                in: 30...240,
                step: 15
            )

            // Bedtime
            HStack {
                Text("No rewards after")
                Spacer()
                Picker("Bedtime", selection: Binding(
                    get: { Int(settings.bedtimeHour) },
                    set: { settings.bedtimeHour = Int32($0); onSave() }
                )) {
                    ForEach(16...23, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                .pickerStyle(.menu)
                .tint(.erBlue)
            }

            // Current balance display
            HStack {
                Text("Current balance")
                Spacer()
                Text(Int(child.starMinutesBalance).asStarMinutesLabel)
                    .foregroundColor(.secondary)
            }

            // Reset balance
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset balance to 0", systemImage: "star.slash")
            }
            .confirmationDialog(
                "Reset Star Minutes balance to 0?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive, action: onResetBalance)
                Button("Cancel", role: .cancel) {}
            }

        } header: {
            Label("Reward Settings", systemImage: "star.fill")
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
