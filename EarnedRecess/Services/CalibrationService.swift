import CoreData
import Foundation

struct CalibrationSuggestion {
    let type: SuggestionType
    let message: String
    let suggestedPassingThreshold: Double?
    let suggestedProgressionThreshold: Double?

    enum SuggestionType { case tooEasy, tooHard, onTrack }
}

final class CalibrationService {
    static let shared = CalibrationService()

    private init() {}

    func analyze(child: ChildProfile, settings: ParentSettings, context: NSManagedObjectContext) -> CalibrationSuggestion? {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "child == %@", child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        request.fetchLimit = Int(settings.calibrationWindow)

        guard let sessions = try? context.fetch(request), sessions.count >= 5 else { return nil }

        let passRate = Double(sessions.filter { $0.passed }.count) / Double(sessions.count)
        let avgScore = sessions.map { $0.averageScore }.reduce(0, +) / Double(sessions.count)

        let currentThreshold = settings.passingThreshold

        if passRate > 0.90 && avgScore > 0.85 {
            let suggested = min(currentThreshold + 0.05, 1.0)
            let currentPct = Int(currentThreshold * 100)
            let suggestedPct = Int(suggested * 100)
            return CalibrationSuggestion(
                type: .tooEasy,
                message: "Your child is excelling! Consider raising the passing threshold from \(currentPct)% to \(suggestedPct)%.",
                suggestedPassingThreshold: suggested,
                suggestedProgressionThreshold: nil
            )
        }

        if passRate < 0.40 || avgScore < 0.45 {
            let suggested = max(currentThreshold - 0.05, 0.40)
            let currentPct = Int(currentThreshold * 100)
            let suggestedPct = Int(suggested * 100)
            return CalibrationSuggestion(
                type: .tooHard,
                message: "Your child is struggling. Consider lowering the passing threshold from \(currentPct)% to \(suggestedPct)%.",
                suggestedPassingThreshold: suggested,
                suggestedProgressionThreshold: nil
            )
        }

        return CalibrationSuggestion(
            type: .onTrack,
            message: "",
            suggestedPassingThreshold: nil,
            suggestedProgressionThreshold: nil
        )
    }
}
