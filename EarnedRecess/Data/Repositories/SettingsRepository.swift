import CoreData
import Foundation

final class SettingsRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getOrCreateSettings() -> ParentSettings {
        let request = ParentSettings.fetchRequest()
        request.fetchLimit = 1
        do {
            if let existing = try context.fetch(request).first {
                return existing
            }
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
        }
        return ParentSettings.createDefaults(context: context)
    }

    func save() {
        CoreDataStack.shared.save()
    }
}
