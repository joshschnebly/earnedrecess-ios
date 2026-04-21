import CoreData
import Foundation

final class SessionRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func todayStarMinutesEarned(for child: ChildProfile) -> Int {
        let request = LetterSession.fetchRequest()
        let startOfDay = Date().startOfDay
        request.predicate = NSPredicate(
            format: "child == %@ AND passed == YES AND sessionDate >= %@",
            child, startOfDay as NSDate
        )
        do {
            let sessions = try context.fetch(request)
            return sessions.reduce(0) { $0 + Int($1.starMinutesEarned) }
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return 0
        }
    }

    func todayMinutesWatched(for child: ChildProfile) -> Int {
        let request = RewardSession.fetchRequest()
        let startOfDay = Date().startOfDay
        request.predicate = NSPredicate(
            format: "child == %@ AND startTime >= %@",
            child, startOfDay as NSDate
        )
        do {
            let sessions = try context.fetch(request)
            return sessions.reduce(0) { $0 + Int($1.minutesWatched) }
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return 0
        }
    }

    func recentRewardSessions(for child: ChildProfile, limit: Int = 20) -> [RewardSession] {
        let request = RewardSession.fetchRequest()
        request.predicate = NSPredicate(format: "child == %@", child)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchLimit = limit
        do {
            return try context.fetch(request)
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func save() {
        CoreDataStack.shared.save()
    }
}
