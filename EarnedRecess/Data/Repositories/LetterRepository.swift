import CoreData
import Foundation

class LetterRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func recentScores(for letter: String, child: ChildProfile, limit: Int = 10) -> [Double] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "letter == %@ AND child == %@ AND passed == YES", letter, child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        request.fetchLimit = limit
        let sessions = (try? context.fetch(request)) ?? []
        return sessions.map { $0.averageScore }
    }

    func allSessions(for child: ChildProfile) -> [LetterSession] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "child == %@", child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func sessions(for letter: String, child: ChildProfile) -> [LetterSession] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "letter == %@ AND child == %@", letter, child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func saveSession(_ session: LetterSession) {
        CoreDataStack.shared.save()
    }
}
