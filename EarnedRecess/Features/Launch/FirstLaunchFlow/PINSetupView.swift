import SwiftUI

struct PINSetupView: View {
    var onComplete: () -> Void

    @State private var stage: Stage = .enter
    @State private var firstPIN: String = ""
    @State private var currentPIN: String = ""
    @State private var errorMessage: String? = nil
    @State private var shakeTrigger: Bool = false

    private enum Stage {
        case enter, confirm
    }

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("🔒")
                    .font(.system(size: 60))
                Text(stage == .enter ? "Create Your Parent PIN" : "Confirm Your PIN")
                    .font(Theme.Fonts.parentHeadline(24))
                Text(stage == .enter
                     ? "You'll use this to access parent settings."
                     : "Enter the same PIN again to confirm.")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 48)

            // PIN dots
            PINDotsView(count: currentPIN.count)
                .shake(trigger: shakeTrigger)

            if let error = errorMessage {
                Text(error)
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.erRed)
            }

            Spacer()

            // Numpad
            NumpadView(onDigit: appendDigit, onDelete: deleteDigit)
                .padding(.bottom, 40)
        }
        .background(Color.erBackground.ignoresSafeArea())
    }

    private func appendDigit(_ digit: String) {
        guard currentPIN.count < 4 else { return }
        currentPIN += digit
        errorMessage = nil
        if currentPIN.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                handlePINComplete()
            }
        }
    }

    private func deleteDigit() {
        guard !currentPIN.isEmpty else { return }
        currentPIN.removeLast()
        errorMessage = nil
    }

    private func handlePINComplete() {
        switch stage {
        case .enter:
            firstPIN = currentPIN
            currentPIN = ""
            stage = .confirm
        case .confirm:
            if currentPIN == firstPIN {
                do {
                    try KeychainService.shared.savePIN(currentPIN)
                    onComplete()
                } catch {
                    showError("Could not save PIN. Please try again.")
                }
            } else {
                showError("PINs don't match. Try again.")
                firstPIN = ""
                currentPIN = ""
                stage = .enter
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        shakeTrigger.toggle()
        currentPIN = ""
    }
}

// MARK: - PIN Dots

struct PINDotsView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < count ? Color.erBlue : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .scaleEffect(index < count ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2), value: count)
            }
        }
    }
}

// MARK: - Numpad

struct NumpadView: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let layout: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(layout, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { key in
                        if key == "" {
                            Color.clear.frame(width: 80, height: 80)
                        } else if key == "⌫" {
                            Button(action: onDelete) {
                                Text(key)
                                    .font(Theme.Fonts.childBody(28))
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(40)
                            }
                        } else {
                            Button(action: { onDigit(key) }) {
                                Text(key)
                                    .font(Theme.Fonts.childBody(32))
                                    .frame(width: 80, height: 80)
                                    .background(Color.erBlue.opacity(0.12))
                                    .cornerRadius(40)
                            }
                        }
                    }
                }
            }
        }
    }
}
