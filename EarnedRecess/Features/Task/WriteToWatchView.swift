import SwiftUI
import PencilKit

struct WriteToWatchView: View {
    @EnvironmentObject var appState: AppState

    let videoTitle: String
    let onSuccess: () -> Void
    let onCancel: () -> Void

    private var letters: [String] {
        let firstWord = videoTitle
            .components(separatedBy: .whitespaces)
            .first(where: { !$0.isEmpty }) ?? videoTitle
        return firstWord.uppercased().unicodeScalars.compactMap { scalar in
            let s = String(scalar)
            return s.range(of: "^[A-Z]$", options: .regularExpression) != nil ? s : nil
        }
    }

    @State private var currentIndex = 0
    @State private var drawing = PKDrawing()
    @State private var canvasSize: CGSize = .zero
    @State private var showFail = false

    private var threshold: Double {
        appState.parentSettings?.writeToWatchThreshold ?? 0.50
    }

    private var currentLetter: String {
        guard currentIndex < letters.count else { return "" }
        return letters[currentIndex]
    }

    private var template: LetterTemplate {
        LetterTemplateLibrary.template(for: currentLetter)
    }

    private var hasEnoughStrokes: Bool {
        drawing.strokes.count >= 2
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                progressDots
                    .padding(.vertical, 12)

                GeometryReader { geo in
                    DrawingCanvasView(
                        drawing: $drawing,
                        template: template,
                        phase: 1
                    )
                    .cornerRadius(16)
                    .padding(Theme.Sizing.smallPadding)
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: currentIndex) { _ in canvasSize = geo.size }
                }

                if showFail {
                    Text("Try again!")
                        .font(Theme.Fonts.childBody(20))
                        .foregroundColor(.red)
                        .padding(.bottom, 4)
                }

                doneBar
            }
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Write to watch: \(firstWordUppercased)")
                .font(Theme.Fonts.childBody(20))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.vertical, 14)
        .background(Color.erBlue)
    }

    private var firstWordUppercased: String {
        let firstWord = videoTitle
            .components(separatedBy: .whitespaces)
            .first(where: { !$0.isEmpty }) ?? videoTitle
        return firstWord.uppercased()
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(letters.indices, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(i < currentIndex ? Color.erGreen :
                              i == currentIndex ? Color.erBlue : Color.gray.opacity(0.3))
                        .frame(width: i == currentIndex ? 14 : 10,
                               height: i == currentIndex ? 14 : 10)

                    if i == currentIndex {
                        Text(letters[i])
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var doneBar: some View {
        HStack(spacing: 16) {
            Button(action: { drawing = .empty; showFail = false }) {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.erBlue)
                    .frame(width: 100, height: 56)
                    .background(Color.erBlue.opacity(0.1))
                    .cornerRadius(14)
            }

            Button(action: submitDrawing) {
                Text("Done ✓")
                    .font(Theme.Fonts.childBody(24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(hasEnoughStrokes ? Color.erGreen : Color.gray.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(!hasEnoughStrokes)
            .animation(.spring(response: 0.2), value: hasEnoughStrokes)
        }
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.vertical, 16)
        .background(Color.erBackground)
    }

    // MARK: - Actions

    private func submitDrawing() {
        let score = ScoringService.shared.score(
            drawing: drawing,
            letter: currentLetter,
            canvasSize: canvasSize
        )

        if score.compositeScore >= threshold {
            showFail = false
            let next = currentIndex + 1
            if next >= letters.count {
                onSuccess()
            } else {
                currentIndex = next
                drawing = .empty
            }
        } else {
            withAnimation { showFail = true }
            drawing = .empty
        }
    }
}
