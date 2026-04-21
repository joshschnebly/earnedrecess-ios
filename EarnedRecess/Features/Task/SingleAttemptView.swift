import SwiftUI
import PencilKit

struct SingleAttemptView: View {
    let letter: String
    let attemptNumber: Int
    let totalAttempts: Int
    var phase: Int = 1
    let onComplete: (DrawingScore, Data?) -> Void

    @EnvironmentObject var appState: AppState

    @State private var drawing = PKDrawing()
    @State private var showScore = false
    @State private var lastScore: DrawingScore = .zero
    @State private var lastInkData: Data? = nil
    @State private var canvasSize: CGSize = .zero
    @State private var showSplash = false

    private var template: LetterTemplate {
        LetterTemplateLibrary.template(for: letter)
    }

    private var hasEnoughStrokes: Bool {
        drawing.strokes.count >= 2
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                attemptHeader

                GeometryReader { geo in
                    DrawingCanvasView(
                        drawing: $drawing,
                        template: template,
                        phase: phase,
                        isEnabled: !showScore,
                        showAlignmentLines: appState.parentSettings?.showAlignmentLines ?? false,
                        templateStyle: appState.parentSettings?.templateStyleEnum ?? .solid,
                        tracingArrowsEnabled: appState.parentSettings?.tracingArrowsEnabled ?? false,
                        tracingArrowsContinuous: appState.parentSettings?.tracingArrowsContinuous ?? true,
                        tracingArrowsSequential: appState.parentSettings?.tracingArrowsSequential ?? false
                    )
                    .cornerRadius(16)
                    .padding(Theme.Sizing.smallPadding)
                    .onAppear { canvasSize = geo.size }
                }

                doneBar
            }

            if showScore {
                AttemptScoreView(
                    score: lastScore,
                    onContinue: advanceAttempt
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            if showSplash {
                LetterIntroSplashView(letter: letter) {
                    showSplash = false
                    speakPrompt()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35), value: showScore)
        .onAppear {
            let soundsEnabled = appState.parentSettings?.letterSoundsEnabled ?? true
            let wordEnabled = appState.parentSettings?.wordAssociationEnabled ?? true
            if attemptNumber == 1 && (soundsEnabled || wordEnabled) {
                showSplash = true
            } else {
                speakPrompt()
            }
        }
    }

    // MARK: - Sub-views

    private var attemptHeader: some View {
        HStack {
            Text("\(attemptNumber) of \(totalAttempts)")
                .font(Theme.Fonts.childCaption())
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 6) {
                ForEach(1...totalAttempts, id: \.self) { i in
                    Circle()
                        .fill(i < attemptNumber ? Color.erGreen :
                              i == attemptNumber ? Color.white : Color.white.opacity(0.35))
                        .frame(width: i == attemptNumber ? 12 : 8,
                               height: i == attemptNumber ? 12 : 8)
                }
            }

            Spacer()

            Text(letter)
                .font(Theme.Fonts.childBody(24))
                .foregroundColor(.white)
        }
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.vertical, 14)
        .background(Color.erBlue)
    }

    private var doneBar: some View {
        HStack(spacing: 16) {
            Button(action: clearCanvas) {
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

    private func speakPrompt() {
        let soundsEnabled = appState.parentSettings?.letterSoundsEnabled ?? true
        let base = "Draw the letter \(letter)"
        if soundsEnabled {
            let phonetic = PhoneticLibrary.phonetic(for: letter)
            let word = PhoneticLibrary.exampleWord(for: letter)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SpeechService.shared.speak("\(base)... \(phonetic)... \(word)")
            }
        } else {
            SpeechService.shared.speak(base)
        }
    }

    private func clearCanvas() {
        withAnimation(.spring(response: 0.3)) { drawing = .empty }
    }

    private func submitDrawing() {
        let score = ScoringService.shared.score(
            drawing: drawing,
            letter: letter,
            canvasSize: canvasSize
        )
        // Capture ink data at submit time — stored in state so advanceAttempt can pass it
        lastInkData = try? drawing.dataRepresentation()
        lastScore = score
        withAnimation { showScore = true }
    }

    private func advanceAttempt() {
        let inkData = lastInkData
        showScore = false
        drawing = .empty
        lastInkData = nil
        onComplete(lastScore, inkData)
    }
}
