import CoreData
import Foundation

@objc(LetterSession)
public class LetterSession: NSManagedObject {}

extension LetterSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LetterSession> {
        NSFetchRequest<LetterSession>(entityName: "LetterSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var letter: String?
    @NSManaged public var sessionDate: Date?
    @NSManaged public var phase: Int16
    @NSManaged public var attemptsRequired: Int16
    @NSManaged public var attemptsCompleted: Int16
    @NSManaged public var averageScore: Double
    @NSManaged public var passed: Bool
    @NSManaged public var starMinutesEarned: Int32
    @NSManaged public var duration: Double
    @NSManaged public var attempts: NSSet?
    @NSManaged public var child: ChildProfile?
}

extension LetterSession {
    static func create(letter: String,
                       phase: Int,
                       attemptsRequired: Int,
                       child: ChildProfile,
                       context: NSManagedObjectContext) -> LetterSession {
        let session = LetterSession(context: context)
        session.id = UUID()
        session.letter = letter
        session.phase = Int16(phase)
        session.attemptsRequired = Int16(attemptsRequired)
        session.attemptsCompleted = 0
        session.sessionDate = Date()
        session.passed = false
        session.averageScore = 0
        session.starMinutesEarned = 0
        session.duration = 0
        session.child = child
        return session
    }

    var attemptsArray: [DrawingAttempt] {
        let set = attempts as? Set<DrawingAttempt> ?? []
        return set.sorted { $0.attemptNumber < $1.attemptNumber }
    }
}

extension LetterSession: Identifiable {}
