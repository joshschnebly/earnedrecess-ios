import CoreData
import Foundation

@objc(ChildProfile)
public class ChildProfile: NSManagedObject {}

extension ChildProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChildProfile> {
        NSFetchRequest<ChildProfile>(entityName: "ChildProfile")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date?
    @NSManaged public var phasePerLetterData: Data?
    @NSManaged public var starMinutesBalance: Int32
    @NSManaged public var totalStarMinutesEarned: Int32
    @NSManaged public var totalStarMinutesSpent: Int32
    @NSManaged public var letterSessions: NSSet?
    @NSManaged public var rewardSessions: NSSet?
}

extension ChildProfile {
    static func create(name: String, context: NSManagedObjectContext) -> ChildProfile {
        let profile = ChildProfile(context: context)
        profile.id = UUID()
        profile.name = name
        profile.createdAt = Date()
        profile.starMinutesBalance = 0
        profile.totalStarMinutesEarned = 0
        profile.totalStarMinutesSpent = 0
        return profile
    }

    var phasePerLetter: [String: Int] {
        get {
            guard let data = phasePerLetterData,
                  let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
            return decoded
        }
        set {
            do {
                phasePerLetterData = try JSONEncoder().encode(newValue)
            } catch {
                print("[EarnedRecess] JSON encode error: \(error.localizedDescription)")
            }
        }
    }

    func phase(for letter: String) -> Int { phasePerLetter[letter] ?? 1 }

    func setPhase(_ phase: Int, for letter: String) {
        var current = phasePerLetter
        current[letter] = phase
        phasePerLetter = current
    }
}

extension ChildProfile: Identifiable {}
