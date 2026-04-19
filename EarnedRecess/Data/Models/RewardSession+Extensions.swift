import CoreData
import Foundation

@objc(RewardSession)
public class RewardSession: NSManagedObject {}

extension RewardSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RewardSession> {
        NSFetchRequest<RewardSession>(entityName: "RewardSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var minutesWatched: Int32
    @NSManaged public var minutesEarned: Int32
    @NSManaged public var videoTitle: String?
    @NSManaged public var videoId: String?
    @NSManaged public var child: ChildProfile?
}

extension RewardSession {
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

extension RewardSession: Identifiable {}
