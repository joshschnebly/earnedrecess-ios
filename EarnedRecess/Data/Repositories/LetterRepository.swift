import CoreData
import Foundation

final class LetterRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func recentScores(for letter: String, child: ChildProfile, limit: Int = 10) -> [Double] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "letter == %@ AND child == %@", letter, child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        request.fetchLimit = limit
        do {
            return try context.fetch(request).map { $0.averageScore }
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func allSessions(for child: ChildProfile) -> [LetterSession] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "child == %@", child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func sessions(for letter: String, child: ChildProfile) -> [LetterSession] {
        let request = LetterSession.fetchRequest()
        request.predicate = NSPredicate(format: "letter == %@ AND child == %@", letter, child)
        request.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func saveSession(_ session: LetterSession) {
        CoreDataStack.shared.save()
    }
}
