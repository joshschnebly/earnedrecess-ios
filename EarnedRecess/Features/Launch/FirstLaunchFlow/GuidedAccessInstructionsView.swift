import SwiftUI

struct GuidedAccessInstructionsView: View {
    var onContinue: () -> Void

    private let steps: [(icon: String, text: String)] = [
        ("gear", "Open the Settings app on your iPad"),
        ("accessibility", "Tap Accessibility"),
        ("lock.shield", "Tap Guided Access and toggle it ON"),
        ("lock", "Tap Passcode Settings → Set Guided Access Passcode"),
        ("exclamationmark.triangle", "Use a DIFFERENT code than your EarnedRecess PIN"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("🔒")
                        .font(.system(size: 60))
                        .padding(.top, 48)
                    Text("Set Up Guided Access")
                        .font(Theme.Fonts.parentHeadline(24))
                    Text("This locks the iPad to Earned Recess so your child can't escape.")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Setup steps
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.erBlue)
                                    .frame(width: 36, height: 36)
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(step.text)
                                .font(Theme.Fonts.parentBody())
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.erCard)
                .cornerRadius(Theme.Sizing.cardCornerRadius)
                .cardShadow()
                .padding(.horizontal)

                // How to start
                VStack(alignment: .leading, spacing: 12) {
                    Text("To START Guided Access each time:")
                        .font(Theme.Fonts.parentHeadline())
                    Text("1. Open Earned Recess\n2. Triple-click the Side Button (or Home button)\n3. Tap \"Start\"")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.erYellow.opacity(0.15))
                .cornerRadius(Theme.Sizing.cardCornerRadius)
                .padding(.horizontal)

                Button("Got It, Continue") {
                    onContinue()
                }
                .buttonStyle(PrimaryButtonStyle(color: .erBlue))
                .padding(.horizontal, Theme.Sizing.padding)
                .padding(.bottom, 40)
            }
        }
        .background(Color.erBackground.ignoresSafeArea())
    }
}
