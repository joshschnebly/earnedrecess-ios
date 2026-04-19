import SwiftUI

struct SessionCompleteView: View {
    let session: LetterSession
    let onWatchYouTube: () -> Void
    let onTryAgain: () -> Void
    let onGoHome: () -> Void

    @State private var phase: AnimationPhase = .idle

    private var passed: Bool { session.passed }
    private var starsEarned: Int { Int(session.starMinutesEarned) }
    private var avgScore: Int { Int(session.averageScore * 100) }

    private enum AnimationPhase {
        case idle, celebrating, showingStats, showingButtons
    }

    var body: some View {
        ZStack {
            // Background
            (passed ? Color.erGreen : Color.erOrange)
                .opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Celebration emoji
                celebrationHero

                Spacer()

                // Stats card
                statsCard
                    .padding(.horizontal, Theme.Sizing.padding)
                    .opacity(phase == .showingStats || phase == .showingButtons ? 1 : 0)
                    .offset(y: phase == .showingStats || phase == .showingButtons ? 0 : 30)
                    .animation(.spring(response: 0.5).delay(0.1), value: phase)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.horizontal, Theme.Sizing.padding)
                    .padding(.bottom, 48)
                    .opacity(phase == .showingButtons ? 1 : 0)
                    .offset(y: phase == .showingButtons ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.15), value: phase)
            }

            // Confetti particles (pass only)
            if passed && phase != .idle {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear { runAnimationSequence() }
    }

    // MARK: - Sub-views

    private var celebrationHero: some View {
        VStack(spacing: 16) {
            Text(passed ? "🎉" : "💪")
                .font(.system(size: 100))
                .scaleEffect(phase == .idle ? 0.3 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: phase)

            Text(passed ? "Amazing!" : "Good try!")
                .font(Theme.Fonts.childTitle(44))
                .foregroundColor(passed ? .erGreen : .erOrange)
                .opacity(phase == .idle ? 0 : 1)
                .animation(.easeIn(duration: 0.3).delay(0.3), value: phase)

            if passed && starsEarned > 0 {
                StarCountView(count: starsEarned, animate: phase != .idle)
            }
        }
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Session Results")
                .font(Theme.Fonts.parentHeadline())
                .foregroundColor(.secondary)

            // Attempt dots
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                ForEach(session.attemptsArray, id: \.id) { attempt in
                    Circle()
                        .fill(attempt.passed ? Color.erGreen : Color.erRed.opacity(0.6))
                        .frame(height: 20)
                        .overlay(
                            Text("\(attempt.starRating)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }

            Divider()

            HStack {
                StatPill(label: "Average", value: "\(avgScore)%", color: scoreColor)
                StatPill(label: "Passed",
                         value: "\(session.attemptsArray.filter { $0.passed }.count)/\(session.attemptsArray.count)",
                         color: .erBlue)
                if passed {
                    StatPill(label: "Earned", value: "+\(starsEarned) ⭐", color: .erGreen)
                }
            }
        }
        .padding(20)
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            if passed && starsEarned > 0 {
                Button(action: onWatchYouTube) {
                    Label("Watch YouTube!", systemImage: "play.tv.fill")
                        .font(Theme.Fonts.childBody(24))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.Sizing.primaryButtonHeight)
                        .background(Color.erGreen)
                        .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
                        .buttonShadow()
                }
            }

            Button(action: onTryAgain) {
                Label("Try Again", systemImage: "arrow.counterclockwise")
                    .font(Theme.Fonts.childBody(22))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.Sizing.primaryButtonHeight)
                    .background(Color.erBlue)
                    .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
                    .buttonShadow()
            }

            Button("Go Home", action: onGoHome)
                .font(Theme.Fonts.parentBody())
                .foregroundColor(.secondary)
        }
    }

    private var scoreColor: Color {
        avgScore >= 80 ? .erGreen : avgScore >= 60 ? .erBlue : .erOrange
    }

    // MARK: - Animation sequence

    private func runAnimationSequence() {
        withAnimation { phase = .celebrating }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { phase = .showingStats }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { phase = .showingButtons }
        }
    }
}

// MARK: - Star count animated display

struct StarCountView: View {
    let count: Int
    let animate: Bool

    @State private var displayCount: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.erYellow)
                .font(.system(size: 28))
            Text("+\(displayCount) Star Minutes!")
                .font(Theme.Fonts.childBody(26))
                .foregroundColor(.erYellow)
                .contentTransition(.numericText())
        }
        .onAppear {
            guard animate else { displayCount = count; return }
            // Count up animation
            let step = max(1, count / 20)
            var current = 0
            Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
                current = min(current + step, count)
                withAnimation(.spring(response: 0.1)) { displayCount = current }
                if current >= count { timer.invalidate() }
            }
        }
    }
}

// MARK: - Stat pill

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Fonts.childBody(20))
                .foregroundColor(color)
            Text(label)
                .font(Theme.Fonts.childCaption(13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    private let colors: [Color] = [.erYellow, .erBlue, .erGreen, .erRed, .erPurple, .erOrange]
    private let count = 60

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                ConfettiPiece(color: colors[i % colors.count], geo: geo)
            }
        }
        .ignoresSafeArea()
    }
}

struct ConfettiPiece: View {
    let color: Color
    let geo: GeometryProxy

    @State private var y: CGFloat = -20
    @State private var x: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private let startX: CGFloat
    private let size: CGFloat
    private let duration: Double

    init(color: Color, geo: GeometryProxy) {
        self.color = color
        self.geo = geo
        self.startX = CGFloat.random(in: 0...geo.size.width)
        self.size = CGFloat.random(in: 8...16)
        self.duration = Double.random(in: 1.8...3.2)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 0.5)
            .rotationEffect(.degrees(rotation))
            .position(x: startX + x, y: y)
            .opacity(opacity)
            .onAppear {
                y = -20
                withAnimation(.easeIn(duration: duration)) {
                    y = geo.size.height + 20
                    x = CGFloat.random(in: -60...60)
                    rotation = Double.random(in: 180...720)
                }
                withAnimation(.easeIn(duration: 0.4).delay(duration - 0.4)) {
                    opacity = 0
                }
            }
    }
}
