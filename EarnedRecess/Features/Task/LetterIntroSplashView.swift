import SwiftUI

struct LetterIntroSplashView: View {
    let letter: String
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.erBlue.ignoresSafeArea()

            VStack(spacing: 16) {
                Text(WordAssociationLibrary.emoji(for: letter))
                    .font(.system(size: 120))

                Text(letter)
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.white)

                Text(WordAssociationLibrary.word(for: letter))
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDismiss() }
            }
        }
    }
}
