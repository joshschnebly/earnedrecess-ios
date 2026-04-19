import CoreData
import Foundation

extension ChildProfile {
    static func fetchRequest() -> NSFetchRequest<ChildProfile> {
        NSFetchRequest<ChildProfile>(entityName: "ChildProfile")
    }

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

    // Phase per letter stored as JSON-encoded [String: Int] in Binary attribute
    var phasePerLetter: [String: Int] {
        get {
            guard let data = phasePerLetterData,
                  let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            phasePerLetterData = try? JSONEncoder().encode(newValue)
        }
    }

    func phase(for letter: String) -> Int {
        phasePerLetter[letter] ?? 1
    }

    func setPhase(_ phase: Int, for letter: String) {
        var current = phasePerLetter
        current[letter] = phase
        phasePerLetter = current
    }
}
