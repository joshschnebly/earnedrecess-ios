import SwiftUI
import CoreData

struct TaskGateView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context
    var onDismiss: () -> Void
    var onWatchYouTube: (() -> Void)? = nil

    @State private var started = false

    private var letter: String {
        guard let settings = appState.parentSettings,
              let child = appState.currentChild else {
            return appState.parentSettings?.activeLetterArray.first ?? "A"
        }
        let active = settings.activeLetterArray
        guard !active.isEmpty else { return "A" }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<LetterSession> = LetterSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "child == %@ AND sessionDate >= %@",
            child, startOfDay as NSDate
        )
        let todaySessions = (try? context.fetch(request)) ?? []

        let practicedToday = Set(todaySessions.letters)
        let unpracticed = active.filter { !practicedToday.contains($0) }

        if let first = unpracticed.first {
            return first
        }

        // All practiced today — pick the one with the lowest averageScore today
        let best = active.min { a, b in
            let scoreA = todaySessions
                .filter { $0.letter == a }
                .map(\.averageScore)
                .reduce(0, +)
            let scoreB = todaySessions
                .filter { $0.letter == b }
                .map(\.averageScore)
                .reduce(0, +)
            return scoreA < scoreB
        }
        return best ?? active[0]
    }
    private var attemptsRequired: Int {
        Int(appState.parentSettings?.attemptsPerSession ?? 10)
    }
    private var starsToEarn: Int {
        Int(appState.parentSettings?.timerDurationMinutes ?? 20)
    }
    private var caseLabel: String {
        letter == letter.uppercased() ? "uppercase" : "lowercase"
    }

    var body: some View {
        ZStack {
            Color.erBackground.ignoresSafeArea()

            if started {
                DrawingSessionView(
                    letter: letter,
                    attemptsRequired: attemptsRequired,
                    onDismiss: onDismiss,
                    onWatchYouTube: onWatchYouTube
                )
            } else {
                gateContent
            }
        }
    }

    private var gateContent: some View {
        VStack(spacing: 36) {
            Spacer()

            // Letter preview
            ZStack {
                Circle()
                    .fill(Color.erBlue.opacity(0.12))
                    .frame(width: 200, height: 200)
                Text(letter)
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.erBlue)
            }

            VStack(spacing: 12) {
                Text("Draw \(attemptsRequired) \(caseLabel) \"\(letter)\"s")
                    .font(Theme.Fonts.childBody(28))
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.erYellow)
                    Text("Earn \(starsToEarn) Star Minutes!")
                        .font(Theme.Fonts.childBody(24))
                        .foregroundColor(.erYellow)
                }
            }
            .padding(.horizontal)

            // Bedtime / daily cap warning
            if let settings = appState.parentSettings {
                if settings.isBedtime {
                    Label("Rewards are paused after bedtime", systemImage: "moon.fill")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.erOrange)
                        .padding(.horizontal)
                } else if Int(appState.currentChild?.starMinutesBalance ?? 0) >= Int(settings.maxDailyMinutes) {
                    Label("Daily maximum reached!", systemImage: "checkmark.seal.fill")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.erGreen)
                        .padding(.horizontal)
                }
            }

            Spacer()

            Button("Let's Draw! ✏️") {
                withAnimation { started = true }
            }
            .buttonStyle(PrimaryButtonStyle(color: .erBlue))
            .padding(.horizontal, Theme.Sizing.padding)

            Button("Maybe Later") { onDismiss() }
                .font(Theme.Fonts.parentBody())
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
    }
}
