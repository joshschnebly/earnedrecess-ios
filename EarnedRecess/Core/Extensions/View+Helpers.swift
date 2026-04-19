import SwiftUI

extension View {
    // Minimum touch target enforced for child UI
    func childTouchTarget() -> some View {
        self.frame(minWidth: Theme.Sizing.minTouchTarget,
                   minHeight: Theme.Sizing.minTouchTarget)
    }

    func primaryCard() -> some View {
        self
            .background(Color.erCard)
            .cornerRadius(Theme.Sizing.cardCornerRadius)
            .cardShadow()
    }

    // Shake animation for PIN failure
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _ in
                withAnimation(.default) { offset = -10 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.default) { offset = 10 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.default) { offset = 0 }
                    }
                }
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .erBlue
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.childBody())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Sizing.primaryButtonHeight)
            .background(isDisabled ? Color.gray.opacity(0.4) : color)
            .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
            .buttonShadow()
    }
}
