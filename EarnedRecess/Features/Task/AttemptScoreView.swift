import SwiftUI

struct AttemptScoreView: View {
    let score: DrawingScore
    let onContinue: () -> Void

    @State private var starsShown: Int = 0
    @State private var messageShown: Bool = false

    private var stars: Int { score.starRating }

    private var message: String {
        switch stars {
        case 3: return ["Amazing!", "Perfect!", "Wow, great job!", "Superstar! ⭐"].randomElement()!
        case 2: return ["Good job!", "Nice try!", "Keep it up!", "Looking good!"].randomElement()!
        default: return ["Try again!", "You can do it!", "Almost there!"].randomElement()!
        }
    }

    private var backgroundColor: Color {
        switch stars {
        case 3: return Color.erGreen.opacity(0.95)
        case 2: return Color.erBlue.opacity(0.95)
        default: return Color.erOrange.opacity(0.95)
        }
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Score card
            VStack(spacing: 28) {
                // Star row
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= starsShown ? "star.fill" : "star")
                            .font(.system(size: 56))
                            .foregroundColor(i <= starsShown ? .erYellow : .white.opacity(0.4))
                            .scaleEffect(i <= starsShown ? 1.2 : 1.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.5)
                                    .delay(Double(i - 1) * 0.15),
                                value: starsShown
                            )
                    }
                }

                // Message
                Text(message)
                    .font(Theme.Fonts.childTitle(36))
                    .foregroundColor(.white)
                    .opacity(messageShown ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.5), value: messageShown)

                // Score breakdown (subtle)
                VStack(spacing: 6) {
                    ScoreRow(label: "Accuracy",   value: score.overlapScore)
                    ScoreRow(label: "Shape",      value: score.proportionScore)
                    ScoreRow(label: "Strokes",    value: score.strokeCountScore)
                    ScoreRow(label: "Smoothness", value: score.smoothnessScore)
                }
                .opacity(messageShown ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.7), value: messageShown)

                // Continue button
                Button(action: onContinue) {
                    Text("Next →")
                        .font(Theme.Fonts.childBody(24))
                        .foregroundColor(backgroundColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
                }
                .opacity(messageShown ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.9), value: messageShown)
            }
            .padding(32)
            .background(backgroundColor)
            .cornerRadius(28)
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Animate stars in one by one
            for i in 1...3 {
                if i <= stars {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i - 1) * 0.2) {
                        starsShown = i
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                messageShown = true
            }
        }
    }
}

struct ScoreRow: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.childCaption(16))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(value))
                }
            }
            .frame(height: 8)

            Text("\(Int(value * 100))%")
                .font(Theme.Fonts.childCaption(14))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, alignment: .trailing)
        }
    }
}
