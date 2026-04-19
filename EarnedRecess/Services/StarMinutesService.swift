import CoreData
import Foundation

class StarMinutesService {
    static let shared = StarMinutesService()
    private init() {}

    // MARK: - Award

    func award(minutes: Int, to child: ChildProfile, settings: ParentSettings, context: NSManagedObjectContext) -> Int {
        guard !settings.isBedtime else { return 0 }

        let todayEarned = SessionRepository(context: context).todayStarMinutesEarned(for: child)
        let dailyRemaining = max(0, Int(settings.maxDailyMinutes) - todayEarned)
        let awarded = min(minutes, dailyRemaining)

        guard awarded > 0 else { return 0 }

        child.starMinutesBalance += Int32(awarded)
        child.totalStarMinutesEarned += Int32(awarded)
        try? context.save()
        return awarded
    }

    // MARK: - Spend

    /// Called each minute while reward player runs. Returns false if balance ran out.
    @discardableResult
    func spendOneMinute(from child: ChildProfile, context: NSManagedObjectContext) -> Bool {
        guard child.starMinutesBalance > 0 else { return false }
        child.starMinutesBalance -= 1
        child.totalStarMinutesSpent += 1
        try? context.save()
        return true
    }

    func spend(minutes: Int, from child: ChildProfile, context: NSManagedObjectContext) {
        let toSpend = min(minutes, Int(child.starMinutesBalance))
        child.starMinutesBalance -= Int32(toSpend)
        child.totalStarMinutesSpent += Int32(toSpend)
        try? context.save()
    }

    // MARK: - Reset

    func resetDailyBalance(for child: ChildProfile, context: NSManagedObjectContext) {
        child.starMinutesBalance = 0
        try? context.save()
    }

    // MARK: - Balance query

    func currentBalance(for child: ChildProfile) -> Int {
        Int(child.starMinutesBalance)
    }
}
