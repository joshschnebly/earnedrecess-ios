import CoreData
import Foundation

extension RewardSession {
    static func fetchRequest() -> NSFetchRequest<RewardSession> {
        NSFetchRequest<RewardSession>(entityName: "RewardSession")
    }

    static func create(minutesEarned: Int,
                       child: ChildProfile,
                       context: NSManagedObjectContext) -> RewardSession {
        let session = RewardSession(context: context)
        session.id = UUID()
        session.startTime = Date()
        session.minutesEarned = Int32(minutesEarned)
        session.minutesWatched = 0
        session.child = child
        return session
    }

    func end(minutesWatched: Int, videoTitle: String?, videoId: String?) {
        self.endTime = Date()
        self.minutesWatched = Int32(minutesWatched)
        self.videoTitle = videoTitle
        self.videoId = videoId
    }

    var durationMinutes: Int {
        guard let end = endTime else { return 0 }
        return Int(end.timeIntervalSince(startTime) / 60)
    }
}
