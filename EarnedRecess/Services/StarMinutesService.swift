import CoreData
import Foundation

final class StarMinutesService {
    static let shared = StarMinutesService()
    private init() {}

    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Award

    func award(minutes: Int, to child: ChildProfile, settings: ParentSettings, context: NSManagedObjectContext) -> Int {
        guard !settings.isBedtime else { return 0 }

        let todayEarned = SessionRepository(context: context).todayStarMinutesEarned(for: child)
        let dailyRemaining = max(0, Int(settings.maxDailyMinutes) - todayEarned)
        let awarded = min(minutes, dailyRemaining)

        guard awarded > 0 else { return 0 }

        child.starMinutesBalance += Int32(awarded)
        child.totalStarMinutesEarned += Int32(awarded)
        do {
            try context.save()
        } catch {
            print("[EarnedRecess] CoreData save error: \(error.localizedDescription)")
        }
        return awarded
    }

    // MARK: - Spend

    /// Called each minute while reward player runs. Returns false if balance ran out.
    @discardableResult
    func spendOneMinute(from child: ChildProfile, context: NSManagedObjectContext) -> Bool {
        guard child.starMinutesBalance > 0 else { return false }
        child.starMinutesBalance -= 1
        child.totalStarMinutesSpent += 1
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveWorkItem = nil
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                print("[EarnedRecess] CoreData save error: \(error.localizedDescription)")
            }
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        return true
    }

    func spend(minutes: Int, from child: ChildProfile, context: NSManagedObjectContext) {
        let toSpend = min(minutes, Int(child.starMinutesBalance))
        child.starMinutesBalance -= Int32(toSpend)
        child.totalStarMinutesSpent += Int32(toSpend)
        do {
            try context.save()
        } catch {
            print("[EarnedRecess] CoreData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset

    func resetDailyBalance(for child: ChildProfile, context: NSManagedObjectContext) {
        child.starMinutesBalance = 0
        do {
            try context.save()
        } catch {
            print("[EarnedRecess] CoreData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Balance query

    func currentBalance(for child: ChildProfile) -> Int {
        Int(child.starMinutesBalance)
    }
}
