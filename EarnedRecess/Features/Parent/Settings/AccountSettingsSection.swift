import SwiftUI
import CoreData
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AccountSettingsSection: View {
    @ObservedObject var child: ChildProfile
    let onSave: () -> Void
    let onResetAll: () -> Void

    @State private var editingName = false
    @State private var draftName: String = ""
    @State private var showChangePIN = false
    @State private var showResetConfirm = false
    @State private var showGuidedAccessGuide = false
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var changePINStage: ChangePINStage = .enterCurrent
    @State private var currentPINEntry = ""
    @State private var newPINEntry = ""
    @State private var confirmPINEntry = ""
    @State private var pinError: String? = nil

    private enum ChangePINStage { case enterCurrent, enterNew, confirm }

    var body: some View {
        Section {
            // Child name
            if editingName {
                HStack {
                    TextField("Child's name", text: $draftName)
                    Button("Save") {
                        child.name = draftName.trimmingCharacters(in: .whitespaces)
                        onSave()
                        editingName = false
                    }
                    .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.erBlue)
                    Button("Cancel") { editingName = false }
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("Child's name")
                    Spacer()
                    Text(child.name)
                        .foregroundColor(.secondary)
                    Button(action: {
                        draftName = child.name
                        editingName = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.erBlue)
                    }
                }
            }

            // Change PIN
            Button(action: { showChangePIN = true }) {
                Label("Change Parent PIN", systemImage: "lock.rotation")
            }
            .foregroundColor(.erBlue)
            .sheet(isPresented: $showChangePIN) {
                changePINSheet
                    .presentationDetents([.medium])
            }

            // Guided Access
            HStack {
                Label("Guided Access", systemImage: "lock.shield")
                Spacer()
                Text(GuidedAccessService.statusLabel)
                    .foregroundColor(GuidedAccessService.isEnabled ? .erGreen : .erOrange)
                    .font(Theme.Fonts.parentBody())
            }

            Button(action: { showGuidedAccessGuide = true }) {
                Label("View Setup Instructions", systemImage: "questionmark.circle")
            }
            .foregroundColor(.erBlue)
            .sheet(isPresented: $showGuidedAccessGuide) {
                GuidedAccessInstructionsView(onContinue: { showGuidedAccessGuide = false })
            }

            // Export data
            Button(action: {
                exportURL = generateCSV()
                showExportSheet = exportURL != nil
            }) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .foregroundColor(.erBlue)
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ActivityView(activityItems: [url])
                }
            }

            // Reset all progress
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset All Progress", systemImage: "trash")
            }
            .confirmationDialog(
                "This will delete all sessions, scores, and star minutes. This cannot be undone.",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive, action: onResetAll)
                Button("Cancel", role: .cancel) {}
            }

        } header: {
            Label("Account", systemImage: "person.circle")
        }
    }

    // MARK: - Change PIN sheet

    private var changePINSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch changePINStage {
                case .enterCurrent:
                    pinField(title: "Enter current PIN", binding: $currentPINEntry)
                    Button("Next") {
                        if KeychainService.shared.verifyPIN(currentPINEntry) {
                            changePINStage = .enterNew
                            pinError = nil
                        } else {
                            pinError = "Incorrect PIN"
                            currentPINEntry = ""
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .erBlue,
                                                    isDisabled: currentPINEntry.count != 4))
                    .disabled(currentPINEntry.count != 4)

                case .enterNew:
                    pinField(title: "Enter new PIN", binding: $newPINEntry)
                    Button("Next") {
                        changePINStage = .confirm
                        pinError = nil
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .erBlue,
                                                    isDisabled: newPINEntry.count != 4))
                    .disabled(newPINEntry.count != 4)

                case .confirm:
                    pinField(title: "Confirm new PIN", binding: $confirmPINEntry)
                    Button("Save PIN") {
                        if confirmPINEntry == newPINEntry {
                            try? KeychainService.shared.changePIN(current: currentPINEntry,
                                                                   new: newPINEntry)
                            showChangePIN = false
                            resetChangePIN()
                        } else {
                            pinError = "PINs don't match"
                            confirmPINEntry = ""
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .erGreen,
                                                    isDisabled: confirmPINEntry.count != 4))
                    .disabled(confirmPINEntry.count != 4)
                }

                if let error = pinError {
                    Text(error)
                        .foregroundColor(.erRed)
                        .font(Theme.Fonts.parentBody())
                }

                Spacer()
            }
            .padding(Theme.Sizing.padding)
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showChangePIN = false
                        resetChangePIN()
                    }
                }
            }
        }
    }

    private func pinField(title: String, binding: Binding<String>) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(Theme.Fonts.parentHeadline())
            PINDotsView(count: binding.wrappedValue.count)
            NumpadView(
                onDigit: { digit in
                    if binding.wrappedValue.count < 4 { binding.wrappedValue += digit }
                },
                onDelete: {
                    if !binding.wrappedValue.isEmpty { binding.wrappedValue.removeLast() }
                }
            )
        }
    }

    private func resetChangePIN() {
        changePINStage = .enterCurrent
        currentPINEntry = ""
        newPINEntry = ""
        confirmPINEntry = ""
        pinError = nil
    }

    private func generateCSV() -> URL? {
        let sessions = (child.letterSessions as? Set<LetterSession> ?? [])
            .sorted { ($0.sessionDate ?? .distantPast) < ($1.sessionDate ?? .distantPast) }

        let formatter = ISO8601DateFormatter()
        var lines = ["date,letter,phase,passed,averageScore,starMinutesEarned"]
        for s in sessions {
            let date = s.sessionDate.map { formatter.string(from: $0) } ?? ""
            let letter = s.letter ?? ""
            let passed = s.passed ? "true" : "false"
            lines.append("\(date),\(letter),\(s.phase),\(passed),\(s.averageScore),\(s.starMinutesEarned)")
        }

        let csv = lines.joined(separator: "\n")
        let fileName = "\(child.name)_sessions.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
