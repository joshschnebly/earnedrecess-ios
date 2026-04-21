import PencilKit
import CoreData

final class ScoringService {
    static let shared = ScoringService()
    private let analyzer = StrokeAnalyzer()
    private let progression = ProgressionEngine()
    private init() {}

    // MARK: - Score a single attempt

    func score(drawing: PKDrawing,
               letter: String,
               canvasSize: CGSize) -> DrawingScore {
        let template = LetterTemplateLibrary.template(for: letter)
        return analyzer.score(drawing: drawing, template: template, canvasSize: canvasSize)
    }

    // MARK: - Finalise a session

    /// Saves all attempts to CoreData, awards star minutes, updates child balance.
    func finaliseSession(letter: String,
                         phase: Int,
                         scores: [DrawingScore],
                         inkDataItems: [Data?],
                         child: ChildProfile,
                         settings: ParentSettings,
                         context: NSManagedObjectContext) -> LetterSession {

        let avgScore = scores.map { $0.compositeScore }.reduce(0, +) / Double(scores.count)
        let passed = avgScore >= settings.passingThreshold

        let session = LetterSession.create(
            letter: letter,
            phase: phase,
            attemptsRequired: scores.count,
            child: child,
            context: context
        )
        session.attemptsCompleted = Int16(scores.count)
        session.averageScore = avgScore
        session.passed = passed

        // Save individual attempts
        for (index, score) in scores.enumerated() {
            let _ = DrawingAttempt.create(
                attemptNumber: index + 1,
                letter: letter,
                overlapScore: score.overlapScore,
                proportionScore: score.proportionScore,
                strokeCountScore: score.strokeCountScore,
                smoothnessScore: score.smoothnessScore,
                compositeScore: score.compositeScore,
                passed: score.passed,
                inkData: inkDataItems[safe: index] ?? nil,
                session: session,
                context: context
            )
        }

        // Award star minutes if passed
        if passed {
            let award = progression.starMinutesAwarded(
                averageScore: avgScore,
                baseDuration: Int(settings.timerDurationMinutes),
                qualityMultiplierEnabled: settings.qualityMultiplierEnabled
            )

            // Daily cap check
            let todayEarned = SessionRepository(context: context).todayStarMinutesEarned(for: child)
            let remaining = Int(settings.maxDailyMinutes) - todayEarned
            let capped = max(0, min(award, remaining))

            session.starMinutesEarned = Int32(capped)
            child.starMinutesBalance += Int32(capped)
            child.totalStarMinutesEarned += Int32(capped)
        }

        // Check phase advancement
        if settings.autoProgressionEnabled {
            let repo = LetterRepository(context: context)
            let recent = repo.recentScores(for: letter, child: child)
            if progression.shouldAdvancePhase(letter: letter,
                                               recentScores: recent,
                                               threshold: settings.progressionThreshold) {
                let next = progression.nextPhase(current: phase)
                child.setPhase(next, for: letter)
            }
        }

        do {
            try context.save()
        } catch {
            print("[EarnedRecess] CoreData save error: \(error.localizedDescription)")
        }
        return session
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
