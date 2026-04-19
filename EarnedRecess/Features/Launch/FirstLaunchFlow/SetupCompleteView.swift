import SwiftUI

struct SetupCompleteView: View {
    let childName: String
    var onFinish: () -> Void

    @State private var showContent: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 90))
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

                Text("You're all set!")
                    .font(Theme.Fonts.childTitle(44))
                    .foregroundColor(.erBlue)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.3), value: showContent)

                Text("Earned Recess is ready for \(childName).")
                    .font(Theme.Fonts.childBody(24))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.5), value: showContent)
            }

            Spacer()

            // Reminder card
            VStack(alignment: .leading, spacing: 12) {
                Text("Before you hand over the iPad:")
                    .font(Theme.Fonts.parentHeadline())

                Label("Enable Guided Access (triple-click side button)", systemImage: "lock.shield")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)

                Label("Your parent PIN unlocks settings anytime", systemImage: "lock")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.erYellow.opacity(0.15))
            .cornerRadius(Theme.Sizing.cardCornerRadius)
            .padding(.horizontal)
            .opacity(showContent ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.7), value: showContent)

            Spacer()

            Button("Let \(childName) Start!") {
                onFinish()
            }
            .buttonStyle(PrimaryButtonStyle(color: .erGreen))
            .padding(.horizontal, Theme.Sizing.padding)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.9), value: showContent)
        }
        .background(Color.erBackground.ignoresSafeArea())
        .onAppear { showContent = true }
    }
}
