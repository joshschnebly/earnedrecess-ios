import SwiftUI

struct TimerExpiredOverlayView: View {
    let onDrawMore: () -> Void
    let onDoneForNow: () -> Void

    @State private var visible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Icon + heading
                VStack(spacing: 16) {
                    Text("⏰")
                        .font(.system(size: 90))
                        .scaleEffect(visible ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.55), value: visible)

                    Text("Time's up!")
                        .font(Theme.Fonts.childTitle(44))
                        .foregroundColor(.white)
                        .opacity(visible ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.3), value: visible)

                    Text("Draw more letters to keep watching!")
                        .font(Theme.Fonts.childBody(24))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .opacity(visible ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: visible)
                }

                // Buttons
                VStack(spacing: 14) {
                    Button(action: onDrawMore) {
                        Label("Draw More Letters ✏️", systemImage: "pencil")
                            .font(Theme.Fonts.childBody(24))
                            .foregroundColor(.erBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.Sizing.primaryButtonHeight)
                            .background(Color.white)
                            .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
                            .buttonShadow()
                    }

                    Button(action: onDoneForNow) {
                        Text("Done for Now")
                            .font(Theme.Fonts.parentBody(18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, Theme.Sizing.padding)
                .opacity(visible ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.7), value: visible)
            }
        }
        .onAppear { visible = true }
    }
}

// MARK: - Timer top bar (shown while reward is playing)

struct RewardTimerBar: View {
    @ObservedObject var timer: RewardTimer
    let onStop: () -> Void

    private var urgentColor: Color {
        timer.remainingSeconds < 60 ? .erRed : .erYellow
    }

    var body: some View {
        HStack(spacing: 12) {
            // Countdown
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(urgentColor)
                    .font(.system(size: 18))
                    .symbolEffect(.pulse, isActive: timer.remainingSeconds < 60)

                Text(timer.displayString)
                    .font(Theme.Fonts.childBody(22))
                    .foregroundColor(urgentColor)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: timer.remainingSeconds)
            }

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(urgentColor)
                        .frame(width: geo.size.width * max(0, CGFloat(timer.progressFraction)))
                        .animation(.linear(duration: 1.0), value: timer.remainingSeconds)
                }
            }
            .frame(height: 8)

            // Stop button
            Button(action: onStop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(Theme.Fonts.childCaption(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.vertical, 12)
        .background(Color.erBlue)
    }
}
