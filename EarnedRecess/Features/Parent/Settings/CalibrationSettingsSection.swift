import SwiftUI

struct CalibrationSettingsSection: View {
    @ObservedObject var settings: ParentSettings
    let onSave: () -> Void

    var body: some View {
        Section {
            Toggle("Auto-calibration suggestions", isOn: Binding(
                get: { settings.autoCalibrationEnabled },
                set: { settings.autoCalibrationEnabled = $0; onSave() }
            ))

            if settings.autoCalibrationEnabled {
                Stepper(
                    "Analyze last \(settings.calibrationWindow) sessions",
                    value: Binding(
                        get: { Int(settings.calibrationWindow) },
                        set: { settings.calibrationWindow = Int32($0); onSave() }
                    ),
                    in: 5...20
                )
            }
        } header: {
            Label("Auto-Calibration", systemImage: "dial.medium")
        }
    }
}
