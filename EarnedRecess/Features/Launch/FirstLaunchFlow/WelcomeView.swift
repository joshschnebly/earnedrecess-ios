import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo / branding area
            VStack(spacing: 16) {
                Text("⭐")
                    .font(.system(size: 100))

                Text("Earned Recess")
                    .font(Theme.Fonts.childTitle(56))
                    .foregroundColor(.erBlue)

                Text("Learn. Earn. Play.")
                    .font(Theme.Fonts.childBody(28))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Welcome, Parent!")
                    .font(Theme.Fonts.parentHeadline(24))

                Text("Let's set up Earned Recess for your child.\nThis takes about 2 minutes.")
                    .font(Theme.Fonts.parentBody())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle(color: .erBlue))
            .padding(.horizontal, Theme.Sizing.padding)
            .padding(.bottom, 40)
        }
        .background(Color.erBackground.ignoresSafeArea())
    }
}
