import SwiftUI

/// Friendly animated mascot shown on the child home screen.
/// Uses a star character with idle bounce + state-based expressions.
/// Replace the emoji/shape with a Lottie animation in a later polish pass.
struct MascotView: View {
    let hasStars: Bool

    @State private var bouncing: Bool = false
    @State private var eyeWink: Bool = false

    var body: some View {
        ZStack {
            // Glow behind mascot
            Circle()
                .fill(hasStars ? Color.erYellow.opacity(0.25) : Color.erBlue.opacity(0.15))
                .frame(width: 180, height: 180)
                .blur(radius: 20)

            // Mascot body
            VStack(spacing: 0) {
                ZStack {
                    // Body
                    RoundedRectangle(cornerRadius: 50)
                        .fill(
                            LinearGradient(
                                colors: hasStars
                                    ? [Color.erYellow, Color.erOrange]
                                    : [Color.erBlue, Color.erPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    // Face
                    VStack(spacing: 12) {
                        // Eyes
                        HStack(spacing: 24) {
                            MascotEye(isWinking: eyeWink)
                            MascotEye(isWinking: false)
                        }

                        // Mouth
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: hasStars ? 50 : 30, height: 10)
                            .animation(.spring(response: 0.4), value: hasStars)
                    }
                }
                .offset(y: bouncing ? -8 : 0)
                .animation(
                    .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: bouncing
                )

                // Shadow
                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 100, height: 16)
                    .scaleEffect(x: bouncing ? 0.85 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: bouncing
                    )
            }
        }
        .onAppear {
            bouncing = true
            // Occasional wink
            startWinkTimer()
        }
    }

    private func startWinkTimer() {
        let interval = Double.random(in: 3.0...6.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            withAnimation(.easeInOut(duration: 0.15)) { eyeWink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.15)) { eyeWink = false }
                startWinkTimer()
            }
        }
    }
}

struct MascotEye: View {
    let isWinking: Bool

    var body: some View {
        if isWinking {
            Capsule()
                .fill(Color.white.opacity(0.9))
                .frame(width: 20, height: 6)
        } else {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: 2)
                )
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        MascotView(hasStars: false)
        MascotView(hasStars: true)
    }
    .padding(40)
    .background(Color.erBackground)
}
