import CoreData
import Foundation

@objc(DrawingAttempt)
public class DrawingAttempt: NSManagedObject {}

extension DrawingAttempt {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawingAttempt> {
        NSFetchRequest<DrawingAttempt>(entityName: "DrawingAttempt")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var attemptNumber: Int16
    @NSManaged public var letter: String?
    @NSManaged public var overlapScore: Double
    @NSManaged public var proportionScore: Double
    @NSManaged public var strokeCountScore: Double
    @NSManaged public var smoothnessScore: Double
    @NSManaged public var compositeScore: Double
    @NSManaged public var passed: Bool
    @NSManaged public var inkData: Data?
    @NSManaged public var timestamp: Date?
    @NSManaged public var session: LetterSession?
}

extension DrawingAttempt {
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

    var starRating: Int {
        switch compositeScore {
        case 0.80...: return 3
        case 0.60...: return 2
        default: return 1
        }
    }
}

extension DrawingAttempt: Identifiable {}
