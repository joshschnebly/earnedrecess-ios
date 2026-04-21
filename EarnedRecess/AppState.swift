import SwiftUI
import CoreData
import Combine

final class AppState: ObservableObject {
    @Published var currentChild: ChildProfile?
    @Published var parentSettings: ParentSettings?
    @Published var starMinutesBalance: Int = 0

    // Shared timer instance — owned here so it survives view transitions
    let rewardTimer = RewardTimer()

    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedSetup")
    }

    func completeSetup() {
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
    }

    func loadChild(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ChildProfile> = ChildProfile.fetchRequest()
        request.fetchLimit = 1
        do {
            currentChild = try context.fetch(request).first
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
        }
        starMinutesBalance = Int(currentChild?.starMinutesBalance ?? 0)
    }

    func loadSettings(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ParentSettings> = ParentSettings.fetchRequest()
        request.fetchLimit = 1
        do {
            if let settings = try context.fetch(request).first {
                parentSettings = settings
            } else {
                parentSettings = ParentSettings.createDefaults(context: context)
            }
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
            parentSettings = ParentSettings.createDefaults(context: context)
        }
    }

    func refreshBalance() {
        starMinutesBalance = Int(currentChild?.starMinutesBalance ?? 0)
    }
}
