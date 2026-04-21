import SwiftUI

struct PINEntryView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var enteredPIN: String = ""
    @State private var attempts: Int = 0
    @State private var isLockedOut: Bool = false
    @State private var lockoutSeconds: Int = 0
    @State private var shakeTrigger: Bool = false
    @State private var errorMessage: String? = nil
    @State private var lockoutTimer: Timer? = nil

    private var isLocked: Bool { isLockedOut && lockoutSeconds > 0 }

    var body: some View {
        ZStack {
            Color.erBackground.ignoresSafeArea()

            VStack(spacing: 36) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.erBlue)
                        .padding(.top, 60)

                    Text("Parent Access")
                        .font(Theme.Fonts.parentHeadline(26))

                    Text(isLocked
                         ? "Too many attempts. Wait \(lockoutSeconds)s."
                         : "Enter your 4-digit PIN")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(isLocked ? .erRed : .secondary)
                }

                // PIN dots
                PINDotsView(count: enteredPIN.count)
                    .shake(trigger: shakeTrigger)

                if let error = errorMessage {
                    Text(error)
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.erRed)
                }

                Spacer()

                // Numpad
                NumpadView(
                    onDigit: { digit in
                        guard !isLocked else { return }
                        appendDigit(digit)
                    },
                    onDelete: deleteDigit
                )
                .disabled(isLocked)
                .opacity(isLocked ? 0.4 : 1.0)

                // Cancel
                Button("Cancel", action: onCancel)
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .onAppear(perform: checkLockout)
        .onDisappear {
            lockoutTimer?.invalidate()
            lockoutTimer = nil
        }
    }

    // MARK: - Logic

    private func appendDigit(_ digit: String) {
        guard enteredPIN.count < 4 else { return }
        enteredPIN += digit
        errorMessage = nil

        if enteredPIN.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                verify()
            }
        }
    }

    private func deleteDigit() {
        guard !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
        errorMessage = nil
    }

    private func verify() {
        if KeychainService.shared.verifyPIN(enteredPIN) {
            KeychainService.shared.setPINAttempts(0)
            KeychainService.shared.setPINLockoutUntil(nil)
            onSuccess()
        } else {
            attempts += 1
            enteredPIN = ""
            shakeTrigger.toggle()

            let remaining = Constants.App.maxPinAttempts - attempts
            if attempts >= Constants.App.maxPinAttempts {
                triggerLockout()
            } else {
                errorMessage = "Wrong PIN. \(remaining) attempt\(remaining == 1 ? "" : "s") left."
                persistAttempts()
            }
        }
    }

    private func triggerLockout() {
        let until = Date().addingTimeInterval(TimeInterval(Constants.App.pinLockoutSeconds))
        KeychainService.shared.setPINLockoutUntil(until)
        KeychainService.shared.setPINAttempts(0)
        attempts = 0
        isLockedOut = true
        lockoutSeconds = Constants.App.pinLockoutSeconds
        errorMessage = nil
        startLockoutCountdown()
    }

    private func startLockoutCountdown() {
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            lockoutSeconds -= 1
            if lockoutSeconds <= 0 {
                isLockedOut = false
                t.invalidate()
            }
        }
    }

    private func persistAttempts() {
        KeychainService.shared.setPINAttempts(attempts)
    }

    private func checkLockout() {
        attempts = KeychainService.shared.getPINAttempts()
        if let until = KeychainService.shared.getPINLockoutUntil() {
            let remaining = Int(until.timeIntervalSinceNow)
            if remaining > 0 {
                isLockedOut = true
                lockoutSeconds = remaining
                startLockoutCountdown()
            } else {
                KeychainService.shared.setPINLockoutUntil(nil)
            }
        }
    }
}
