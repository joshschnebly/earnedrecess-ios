import SwiftUI
import PencilKit
import CoreData

struct DrawingSessionView: View {
    let letter: String
    let attemptsRequired: Int
    let onDismiss: () -> Void

    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    @State private var currentAttempt: Int = 1
    @State private var scores: [DrawingScore] = []
    @State private var inkDataItems: [Data?] = []
    @State private var sessionComplete: Bool = false
    @State private var completedSession: LetterSession? = nil
    @State private var sessionStartTime = Date()

    private var effectiveLetter: String {
        let lc = appState.parentSettings?.letterCase ?? "uppercase"
        switch lc {
        case "lowercase": return letter.lowercased()
        case "both": return Bool.random() ? letter.uppercased() : letter.lowercased()
        default: return letter.uppercased()
        }
    }

    private var phase: Int {
        appState.currentChild?.phase(for: letter) ?? 1
    }

    var body: some View {
        ZStack {
            if sessionComplete, let session = completedSession {
                SessionCompleteView(
                    session: session,
                    onWatchYouTube: {
                        appState.refreshBalance()
                        onDismiss()
                    },
                    onTryAgain: resetSession,
                    onGoHome: {
                        appState.refreshBalance()
                        onDismiss()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else {
                SingleAttemptView(
                    letter: effectiveLetter,
                    attemptNumber: currentAttempt,
                    totalAttempts: attemptsRequired,
                    phase: phase,
                    onComplete: handleAttemptComplete
                )
                .id(currentAttempt)  // force re-init for each attempt
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.spring(response: 0.4), value: currentAttempt)
        .animation(.spring(response: 0.4), value: sessionComplete)
    }

    // MARK: - Attempt handling

    private func handleAttemptComplete(_ score: DrawingScore, _ inkData: Data?) {
        scores.append(score)
        inkDataItems.append(inkData)

        if currentAttempt < attemptsRequired {
            currentAttempt += 1
        } else {
            finaliseSession()
        }
    }

    private func finaliseSession() {
        guard let child = appState.currentChild,
              let settings = appState.parentSettings else { return }

        let session = ScoringService.shared.finaliseSession(
            letter: letter,
            phase: phase,
            scores: scores,
            inkDataItems: inkDataItems,
            child: child,
            settings: settings,
            context: context
        )
        session.duration = Date().timeIntervalSince(sessionStartTime)
        try? context.save()

        completedSession = session
        withAnimation { sessionComplete = true }
    }

    private func resetSession() {
        scores = []
        inkDataItems = []
        currentAttempt = 1
        completedSession = nil
        sessionStartTime = Date()
        withAnimation { sessionComplete = false }
    }
}
