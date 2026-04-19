import CoreData
import Foundation

class SessionRepository {
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
        let sessions = (try? context.fetch(request)) ?? []
        return sessions.reduce(0) { $0 + Int($1.starMinutesEarned) }
    }

    func todayMinutesWatched(for child: ChildProfile) -> Int {
        let request = RewardSession.fetchRequest()
        let startOfDay = Date().startOfDay
        request.predicate = NSPredicate(
            format: "child == %@ AND startTime >= %@",
            child, startOfDay as NSDate
        )
        let sessions = (try? context.fetch(request)) ?? []
        return sessions.reduce(0) { $0 + Int($1.minutesWatched) }
    }

    func recentRewardSessions(for child: ChildProfile, limit: Int = 20) -> [RewardSession] {
        let request = RewardSession.fetchRequest()
        request.predicate = NSPredicate(format: "child == %@", child)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }

    func save() {
        CoreDataStack.shared.save()
    }
}
