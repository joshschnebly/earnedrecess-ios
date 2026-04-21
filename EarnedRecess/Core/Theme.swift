import SwiftUI

enum Theme {
    // MARK: - Colors
    enum Colors {
        static let primaryYellow = Color("PrimaryYellow")      // star/reward color
        static let primaryBlue = Color("PrimaryBlue")          // draw action color
        static let primaryGreen = Color("PrimaryGreen")        // success/pass color
        static let primaryRed = Color("PrimaryRed")            // fail/warning color
        static let backgroundLight = Color("BackgroundLight")  // main bg
        static let cardBackground = Color("CardBackground")    // card surfaces

        // Fallbacks for preview (before asset catalog is set up)
        static let yellow = Color(red: 1.0, green: 0.84, blue: 0.0)
        static let blue = Color(red: 0.27, green: 0.53, blue: 0.96)
        static let green = Color(red: 0.30, green: 0.80, blue: 0.40)
        static let red = Color(red: 0.96, green: 0.36, blue: 0.36)
        static let background = Color(red: 0.97, green: 0.97, blue: 1.0)
        static let card = Color.white
    }

    // MARK: - Typography
    enum Fonts {
        static func childTitle(_ size: CGFloat = 48) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static func childBody(_ size: CGFloat = 28) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func childCaption(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        static func parentBody(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func parentHeadline(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func parentCaption(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
    }

    // MARK: - Spacing & Sizing
    enum Sizing {
        static let minTouchTarget: CGFloat = 60    // minimum tap area for child UI
        static let primaryButtonHeight: CGFloat = 80
        static let primaryButtonCornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 16
        static let padding: CGFloat = 24
        static let smallPadding: CGFloat = 12
    }

    // MARK: - Shadows
    enum Shadows {
        static let card = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        static let button = Shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func cardShadow() -> some View {
        self.shadow(color: Theme.Shadows.card.color,
                    radius: Theme.Shadows.card.radius,
                    x: Theme.Shadows.card.x,
                    y: Theme.Shadows.card.y)
    }

    func buttonShadow() -> some View {
        self.shadow(color: Theme.Shadows.button.color,
                    radius: Theme.Shadows.button.radius,
                    x: Theme.Shadows.button.x,
                    y: Theme.Shadows.button.y)
    }
}
