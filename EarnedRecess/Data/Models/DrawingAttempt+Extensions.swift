import CoreData
import Foundation

extension DrawingAttempt {
    static func fetchRequest() -> NSFetchRequest<DrawingAttempt> {
        NSFetchRequest<DrawingAttempt>(entityName: "DrawingAttempt")
    }

    static func create(attemptNumber: Int,
                       letter: String,
                       overlapScore: Double,
                       proportionScore: Double,
                       strokeCountScore: Double,
                       smoothnessScore: Double,
                       compositeScore: Double,
                       passed: Bool,
                       inkData: Data?,
                       session: LetterSession,
                       context: NSManagedObjectContext) -> DrawingAttempt {
        let attempt = DrawingAttempt(context: context)
        attempt.id = UUID()
        attempt.attemptNumber = Int16(attemptNumber)
        attempt.letter = letter
        attempt.overlapScore = overlapScore
        attempt.proportionScore = proportionScore
        attempt.strokeCountScore = strokeCountScore
        attempt.smoothnessScore = smoothnessScore
        attempt.compositeScore = compositeScore
        attempt.passed = passed
        attempt.inkData = inkData
        attempt.timestamp = Date()
        attempt.session = session
        return attempt
    }

    // 1–3 star rating for child display
    var starRating: Int {
        switch compositeScore {
        case 0.80...: return 3
        case 0.60...: return 2
        default: return 1
        }
    }
}
