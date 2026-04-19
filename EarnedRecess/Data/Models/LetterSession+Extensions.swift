import CoreData
import Foundation

extension LetterSession {
    static func fetchRequest() -> NSFetchRequest<LetterSession> {
        NSFetchRequest<LetterSession>(entityName: "LetterSession")
    }

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
