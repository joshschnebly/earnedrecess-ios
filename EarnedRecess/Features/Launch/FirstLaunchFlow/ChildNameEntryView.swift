import SwiftUI

struct ChildNameEntryView: View {
    var onComplete: (String) -> Void

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 1
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Text("👶")
                    .font(.system(size: 70))
                Text("What's your child's name?")
                    .font(Theme.Fonts.parentHeadline(24))
                Text("This is shown on their home screen.")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
            }

            TextField("Child's first name", text: $name)
                .font(Theme.Fonts.childBody(28))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.erCard)
                .cornerRadius(Theme.Sizing.cardCornerRadius)
                .cardShadow()
                .padding(.horizontal, Theme.Sizing.padding)
                .focused($isFocused)
                .onSubmit {
                    if isValid { submit() }
                }

            Spacer()

            Button("Continue") {
                submit()
            }
            .buttonStyle(PrimaryButtonStyle(color: .erBlue, isDisabled: !isValid))
            .disabled(!isValid)
            .padding(.horizontal, Theme.Sizing.padding)
            .padding(.bottom, 40)
        }
        .background(Color.erBackground.ignoresSafeArea())
        .onAppear { isFocused = true }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onComplete(trimmed)
    }
}
