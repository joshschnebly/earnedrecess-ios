import SwiftUI
import CoreData
import Combine

class AppState: ObservableObject {
    @Published var currentChild: ChildProfile?
    @Published var parentSettings: ParentSettings?
    @Published var isParentSessionActive: Bool = false
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
        currentChild = try? context.fetch(request).first
        starMinutesBalance = Int(currentChild?.starMinutesBalance ?? 0)
    }

    func loadSettings(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ParentSettings> = ParentSettings.fetchRequest()
        request.fetchLimit = 1
        if let settings = try? context.fetch(request).first {
            parentSettings = settings
        } else {
            parentSettings = ParentSettings.createDefaults(context: context)
        }
    }

    func refreshBalance() {
        starMinutesBalance = Int(currentChild?.starMinutesBalance ?? 0)
    }
}
