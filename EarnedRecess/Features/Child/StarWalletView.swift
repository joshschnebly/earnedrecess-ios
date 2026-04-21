import SwiftUI

/// Full star wallet display — shown on home screen between mascot and buttons.
/// The top bar version (StarWalletTopBar) lives in ChildHomeView.
struct StarWalletView: View {
    let balance: Int
    @State private var animatedBalance: Int = 0
    @State private var showBurst: Bool = false

    private let maxDisplayStars = 5
    private var starsFilled: Int {
        balance > 0 ? min(maxDisplayStars, max(1, balance / 20)) : 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Star icons row
            HStack(spacing: 12) {
                ForEach(0..<maxDisplayStars, id: \.self) { index in
                    Image(systemName: index < starsFilled ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundColor(index < starsFilled ? .erYellow : .gray.opacity(0.3))
                        .scaleEffect(showBurst && index < starsFilled ? 1.3 : 1.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.5)
                                .delay(Double(index) * 0.08),
                            value: showBurst
                        )
                }
            }

            // Numeric balance
            Text(animatedBalance.asStarMinutesLabel)
                .font(Theme.Fonts.childBody(26))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5), value: animatedBalance)

            if balance > 0 {
                Text("That's \(balance) minutes of YouTube!")
                    .font(Theme.Fonts.childCaption())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            animatedBalance = balance
            if balance > 0 {
                withAnimation { showBurst = true }
            }
        }
        .onChange(of: balance) { _, newValue in
            let increased = newValue > animatedBalance
            withAnimation { animatedBalance = newValue }
            if increased {
                showBurst = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { showBurst = true }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        StarWalletView(balance: 0)
        StarWalletView(balance: 20)
        StarWalletView(balance: 65)
    }
    .padding()
    .background(Color.erBackground)
}
